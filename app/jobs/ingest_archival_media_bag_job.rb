# frozen_string_literal: true
require "bagit"

# Job for ingesting ArchivalMediaCollection objects as Bags
# @see https://tools.ietf.org/html/draft-kunze-bagit-14 BagIt File Packaging Format
# Please note that this is typically invoked when any given ArchivalMediaCollection is persisted
# (see ChangeSetPersister.registered_handlers and ChangeSetPersister::IngestBag)
class IngestArchivalMediaBagJob < ApplicationJob
  class InvalidBagError < StandardError; end

  BARCODE_WITH_PART_REGEX = /(\d{14}_\d+)_.*/

  def perform(collection_component:, bag_path:, user:)
    bag_path = Pathname.new(bag_path.to_s)
    bag = ArchivalMediaBagParser.new(path: bag_path, component_id: collection_component)
    raise InvalidBagError, "Bag at #{bag_path} is an invalid bag" unless bag.valid?
    changeset_persister.buffer_into_index do |buffered_persister|
      amc = find_or_create_amc(collection_component)
      Ingester.new(collection: amc, bag: bag, user: user, changeset_persister: buffered_persister).ingest
    end
  end

  private

    def find_or_create_amc(component_id)
      existing_amc = metadata_adapter.query_service.custom_queries
                                     .find_by_string_property(property: :source_metadata_identifier, value: component_id)
                                     .select { |r| r.is_a? ArchivalMediaCollection }.first
      return existing_amc unless existing_amc.nil?
      change_set = DynamicChangeSet.new(ArchivalMediaCollection.new)
      change_set.validate(source_metadata_identifier: component_id)
      changeset_persister.save(change_set: change_set)
    end

    def changeset_persister
      @changeset_persister ||= ChangeSetPersister.new(metadata_adapter: metadata_adapter,
                                                      storage_adapter: storage_adapter,
                                                      queue: queue_name)
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    def storage_adapter
      Valkyrie::StorageAdapter.find(:disk_via_copy)
    end

    # Service Class for ingesting the bag as a procedure
    class Ingester
      attr_reader :collection, :bag, :user, :changeset_persister

      # Constructor
      # @param collection [ArchivalMediaCollection]
      # @param bag [ArchivalMediaBagParser] bag parser Object
      # @param user [User]
      # @param changeset_persister [ChangeSetPersister] persister used for storing the bag
      def initialize(collection:, bag:, user:, changeset_persister:)
        @collection = collection
        @bag = bag
        @user = user
        @changeset_persister = changeset_persister
      end

      # Method for procedurally ingesting the bag
      # Each component ID may be mapped to one or many physical "sides" of a media object (e. g. an audio tape)
      # These sides are logically modeled using a barcode-based identifier
      def ingest
        component_groups.each do |cid, sides|
          media_resource_change_set = find_or_create_media_resource(cid)
          add_av(media_resource_change_set, sides)
          add_pbcore(media_resource_change_set, sides)
          add_images(media_resource_change_set, sides)
          media_resource_change_set.member_of_collection_ids += [collection.id]
          changeset_persister.save(change_set: media_resource_change_set)
        end
      end

      private

        # Constructs an for IngestableFile the image associated with the asset
        # @param barcode [String] the component ID for an asset in the Bag
        # @return [IngestableFile] the file used to create the FileSet upon persistence (by the FileAppender)
        def create_image_file(barcode)
          image = bag.image_file(barcode: barcode)
          IngestableFile.new(file_path: image.path, mime_type: image.mime_type, original_filename: image.original_filename)
        end

        # Adds any images related to the item as member FileSets
        # @param media_resource_change_set [MediaResourceChangeSet]
        # @param sides [Array<String>] the component IDs for the logical sides of an asset
        def add_images(media_resource_change_set, sides)
          sides.map { |side| side.split("_").first }.uniq.each do |barcode|
            file = create_image_file(barcode)
            media_resource_change_set.files << file
            media_resource_change_set.sync
          end
        end

        def add_av(media_resource_change_set, sides)
          sides.each do |side|
            file_set = create_av_file_set(side)
            media_resource_change_set.member_ids += [file_set.id]
            media_resource_change_set.sync
          end
        end

        def add_pbcore(media_resource_change_set, sides)
          sides.map { |side| side.split("_").first }.uniq.each do |barcode|
            file = create_pbcore_file(barcode)
            media_resource_change_set.files << file
            media_resource_change_set.sync
          end
        end

        # Creates and persists a FileSet for a pbcore xml file
        # @param barcode [String] barcode_side for a given media object
        # @return [IngestableFile] the file used to create the FileSet upon persistence (by the FileAppender)
        def create_pbcore_file(barcode)
          pbcore = bag.pbcore_parser_for_barcode(barcode)
          IngestableFile.new(file_path: pbcore.path, mime_type: "application/xml; schema=pbcore", original_filename: pbcore.original_filename)
        end

        # Creates and persists a FileSet for a media object
        # @param barcode_with_side [String] barcode_side for a given media object
        # @return [FileSet] the persisted FileSet containing the binary and file metadata
        def create_av_file_set(barcode_with_side)
          file_set = FileSet.new(title: barcode_with_side)
          bag.file_groups[barcode_with_side].each do |ingestable_audio_file| # this is an IngestableAudioFile object
            file_metadata_node = create_node(ingestable_audio_file)
            file_set.barcode = ingestable_audio_file.barcode
            file_set.part = ingestable_audio_file.part
            file_set.transfer_notes = bag.pbcore_parser_for_barcode(ingestable_audio_file.barcode).transfer_notes
            file_set.file_metadata += [file_metadata_node]
          end
          file_set = changeset_persister.save(change_set: FileSetChangeSet.new(file_set))
        end

        # Creates file metadata and uploads a binary file
        # @param file [IngestableAudioFile] the audio file being uploaded
        # @return [FileMetadata]
        def create_node(ingestable_audio_file)
          attributes = { id: SecureRandom.uuid }
          file_metadata_node = FileMetadata.for(file: ingestable_audio_file).new(attributes)
          file = storage_adapter.upload(file: ingestable_audio_file, resource: file_metadata_node, original_filename: ingestable_audio_file.original_filename)
          file_metadata_node.file_identifiers = file_metadata_node.file_identifiers + [file.id]
          file_metadata_node
        end

        # Creates or finds an existing MediaResource Object using an EAD Component ID
        # @param component_id [String]
        # @return [MediaResourceChangeSet]
        def find_or_create_media_resource(component_id)
          results = query_service.custom_queries.find_by_string_property(property: :source_metadata_identifier, value: component_id)
          media_resource = results.size.zero? ? MediaResource.new : results.first
          MediaResourceChangeSet.new(media_resource, source_metadata_identifier: component_id, files: [])
        end

        # Retrieve a Hash of EAD Component IDs/Barcodes for file barcodes specified in a given Bag
        # @return [Hash] map of EAD component IDs to file barcodes
        def component_groups
          @component_groups ||= bag.component_groups
        end

        def storage_adapter
          Valkyrie::StorageAdapter.find(:disk_via_copy)
        end

        def query_service
          Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
        end
    end

  # end private
end
