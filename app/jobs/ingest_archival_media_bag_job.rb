# frozen_string_literal: true
require "bagit"

# Job for ingesting ArchivalMediaCollection objects as Bags
# @see https://tools.ietf.org/html/draft-kunze-bagit-14 BagIt File Packaging Format
# Please note that this is typically invoked when any given ArchivalMediaCollection is persisted
# (see ChangeSetPersister.registered_handlers and ChangeSetPersister::IngestBag)
class IngestArchivalMediaBagJob < ApplicationJob
  BARCODE_WITH_PART_REGEX = /(\d{14}_\d+)_.*/

  def perform(collection_component:, bag_path:, user:)
    bag_path = Pathname.new(bag_path.to_s)
    bag = ArchivalMediaBagParser.new(path: bag_path, component_id: collection_component)
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
          media_resource = find_or_create_media_resource(cid)
          media_resource_change_set = MediaResourceChangeSet.new(media_resource, source_metadata_identifier: media_resource.source_metadata_identifier.first)
          add_av(media_resource_change_set, sides)
          add_pbcore(media_resource_change_set, sides)
          media_resource_change_set.member_of_collection_ids += [collection.id]
          changeset_persister.save(change_set: media_resource_change_set)
        end
      end

      private

        def add_av(media_resource_change_set, sides)
          sides.each do |side|
            file_set = create_av_file_set(side)
            media_resource_change_set.member_ids += [file_set.id]
            media_resource_change_set.sync
          end
        end

        def add_pbcore(media_resource_change_set, sides)
          sides.map { |side| side.split("_").first }.uniq.each do |barcode|
            file_set = create_pbcore_file_set(barcode)
            media_resource_change_set.member_ids += [file_set.id]
            media_resource_change_set.sync
          end
        end

        # Creates and persists a FileSet for a pbcore xml file
        # @param barcode [String] barcode_side for a given media object
        # @return [FileSet] the persisted FileSet containing the binary and file metadata
        def create_pbcore_file_set(barcode)
          file_set = FileSet.new(title: barcode)
          pbcore = bag.pbcore_parser_for_barcode(barcode)
          file = IngestableFile.new(file_path: pbcore.path, mime_type: "application/xml; schema=pbcore", original_filename: pbcore.original_filename)
          node = create_node(file)
          file_set.file_metadata += [node]
          changeset_persister.save(change_set: FileSetChangeSet.new(file_set))
        end

        # Creates and persists a FileSet for a media object
        # @param barcode_with_side [String] barcode_side for a given media object
        # @return [FileSet] the persisted FileSet containing the binary and file metadata
        def create_av_file_set(barcode_with_side)
          file_set = FileSet.new(title: barcode_with_side)
          bag.file_groups[barcode_with_side].each do |file| # this is an IngestableAudioFile object
            node = create_node(file)
            file_set.barcode = file.barcode
            file_set.part = file.part
            file_set.transfer_notes = bag.pbcore_parser_for_barcode(file.barcode).transfer_notes
            file_set.file_metadata += [node]
          end
          file_set = changeset_persister.save(change_set: FileSetChangeSet.new(file_set))
        end

        # Creates file metadata and uploads a binary file
        # @param file [File] the file being uploaded
        # @return [FileMetadata]
        def create_node(file)
          attributes = { id: SecureRandom.uuid }
          node = FileMetadata.for(file: file).new(attributes)
          file = storage_adapter.upload(file: file, resource: node, original_filename: file.original_filename)
          node.file_identifiers = node.file_identifiers + [file.id]
          node
        end

        # Creates or finds an existing MediaResource Object using an EAD Component ID
        # @param component_id [String]
        # @return [MediaResource]
        def find_or_create_media_resource(component_id)
          results = query_service.custom_queries.find_by_string_property(property: :source_metadata_identifier, value: component_id)
          return results.first unless results.size.zero?
          MediaResource.new(source_metadata_identifier: component_id)
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
