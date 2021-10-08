# frozen_string_literal: true
require "bagit"

# Job for ingesting Collection (ArchivalMediaCollections) objects as Bags
# @see https://tools.ietf.org/html/draft-kunze-bagit-14 BagIt File Packaging Format
# Please note that this is typically invoked when any given ArchivalMediaCollection is persisted
# (see ChangeSetPersister.registered_handlers and ChangeSetPersister::IngestBag)
class IngestArchivalMediaBagJob < ApplicationJob
  class InvalidBagError < StandardError; end

  BARCODE_WITH_SIDE_REGEX = /(\d{14}_\d+)_.*/.freeze

  def perform(collection_component:, bag_path:, user:)
    bag_path = Pathname.new(bag_path.to_s)
    # This requires a resource
    bag = ArchivalMediaBagParser.new(path: bag_path, component_id: collection_component)
    raise InvalidBagError, "Bag at #{bag_path} is an invalid bag" unless bag.valid?
    changeset_persister.buffer_into_index do |buffered_persister|
      amc = find_or_create_amc(collection_component)
      Ingester.new(collection: amc, bag: bag, user: user, changeset_persister: buffered_persister).ingest
    end
  end

  private

    def change_set_class
      ArchivalMediaCollectionChangeSet
    end

    def find_or_create_amc(component_id)
      existing_amc = metadata_adapter.query_service.custom_queries
                                     .find_by_property(property: :source_metadata_identifier, value: component_id)
                                     .select { |r| r.is_a? Collection }.first
      return existing_amc unless existing_amc.nil?
      change_set = change_set_class.new(Collection.new)
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
      attr_reader :collection, :bag, :user, :changeset_persister, :upload_set_id
      delegate :storage_adapter, :metadata_adapter, to: :changeset_persister
      delegate :query_service, to: :metadata_adapter
      delegate :barcode_groups, to: :bag

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
        @upload_set_id = Valkyrie::ID.new(SecureRandom.uuid)
      end

      delegate :barcodes, to: :bag
      # Method for procedurally ingesting the bag
      # Each component ID may be mapped to one or many physical "sides" of a media object (e. g. an audio tape)
      # These sides are logically modeled using a barcode-based identifier
      def ingest
        barcode_lookup = Hash.new([])
        barcodes.each do |barcode|
          recording_change_set = find_or_create_recording(:local_identifier, barcode)
          pbcore = bag.pbcore_parser(barcode: barcode)
          bag.audio_files_for_barcode(barcode: barcode).sort_by(&:first).each do |file_set_title, audio_files|
            file_set = FileSet.new(
              title: file_set_title,
              side: audio_files.first.side,
              part: audio_files.first.part,
              barcode: barcode,
              transfer_notes: pbcore&.transfer_notes,
              read_groups: file_set_read_groups
            )

            audio_files.each do |ingestable_audio_file|
              file_metadata_node = create_node(ingestable_audio_file)
              file_set.file_metadata += [file_metadata_node]
            end

            file_set = changeset_persister.save(change_set: FileSetChangeSet.new(file_set))
            recording_change_set.created_file_sets += [file_set]
            recording_change_set.member_ids += [file_set.id]
          end
          create_and_attach_file(pbcore, recording_change_set) if pbcore
          recording_change_set.title = pbcore&.main_title

          image = bag.image_file(barcode: barcode)
          create_and_attach_file(image, recording_change_set) if image

          persisted = changeset_persister.save(change_set: recording_change_set)
          barcode_lookup[barcode] += [persisted.id]
        end
        build_descriptive_proxies(barcode_lookup)
      end

      def create_and_attach_file(builder, recording_change_set)
        file = IngestableFile.new(
          file_path: builder.path,
          mime_type: builder.mime_type,
          original_filename: builder.original_filename,
          container_attributes: { read_groups: file_set_read_groups }
        )
        recording_change_set.files << file
      end

      def build_descriptive_proxies(barcode_lookup)
        DescriptiveProxyBuilder.new(
          barcode_lookup: barcode_lookup,
          component_groups: component_groups,
          changeset_persister: changeset_persister,
          collection: collection,
          recording_attributes: {
            upload_set_id: upload_set_id,
            rights_statement: RightsStatements.copyright_not_evaluated
          }
        ).build!
      end

      class DescriptiveProxyBuilder
        attr_reader :barcode_lookup, :component_groups, :changeset_persister, :recording_attributes, :collection
        delegate :query_service, to: :changeset_persister
        def initialize(barcode_lookup:, component_groups:, changeset_persister:, collection:, recording_attributes: {})
          @barcode_lookup = barcode_lookup
          @component_groups = component_groups
          @changeset_persister = changeset_persister
          @recording_attributes = recording_attributes
          @collection = collection
        end

        def build!
          component_groups.each do |component_id, barcodes|
            component_change_set = find_or_create_recording(:source_metadata_identifier, component_id)
            component_change_set.validate(
              member_ids: barcodes.flat_map { |b| barcode_lookup[b] },
              member_of_collection_ids: [collection.id]
            )
            if component_id.nil?
              component_change_set.validate(
                title: "[Unorganized Barcodes]",
                local_identifier: "unorganized"
              )
            end
            changeset_persister.save(change_set: component_change_set)
          end
        end

        # Creates or finds an existing Recording Object using an EAD Component ID
        # @param component_id [String]
        # @return [RecordingChangeSet]
        def find_or_create_recording(property, value)
          results = value.nil? ? [] : query_service.custom_queries.find_by_property(property: property, value: value)
          recording = results.size.zero? ? ScannedResource.new : results.first
          RecordingChangeSet.new(
            recording,
            property => value,
            visibility: collection.visibility.first,
            downloadable: "public",
            **recording_attributes
          )
        end
      end

      private

        # get the correct read groups based on the collection visibility
        def file_set_read_groups
          case collection.visibility.first
          when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
          when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
          when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
            []
          end
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

        # Creates or finds an existing Recording Object using an EAD Component ID
        # @param component_id [String]
        # @return [RecordingChangeSet]
        def find_or_create_recording(property, value)
          results = value.nil? ? [] : query_service.custom_queries.find_by_property(property: property, value: value)
          recording = results.size.zero? ? ScannedResource.new : results.first
          RecordingChangeSet.new(
            recording,
            property => value,
            files: [],
            visibility: collection.visibility.first,
            upload_set_id: upload_set_id,
            downloadable: "public",
            rights_statement: RightsStatements.copyright_not_evaluated
          )
        end

        # Retrieve a Hash of EAD Component IDs/Barcodes for file barcodes specified in a given Bag
        # @return [Hash] map of EAD component IDs to file barcodes
        def component_groups
          @component_groups ||= bag.component_groups
        end
    end
end
