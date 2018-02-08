# frozen_string_literal: true
module Bagit
  class BagImporter
    attr_reader :bag_storage_adapter, :bag_metadata_adapter, :metadata_adapter, :storage_adapter
    def initialize(bag_metadata_adapter:, bag_storage_adapter:, metadata_adapter:, storage_adapter:)
      @bag_metadata_adapter = bag_metadata_adapter
      @bag_storage_adapter = bag_storage_adapter
      @metadata_adapter = metadata_adapter
      @storage_adapter = storage_adapter
    end

    def import(id:)
      output = nil
      metadata_adapter.persister.buffer_into_index do |transaction_adapter|
        output = ResourceImporter.new(
          bag_storage_adapter: bag_storage_adapter.for(bag_id: id),
          bag_metadata_adapter: bag_metadata_adapter,
          metadata_adapter: transaction_adapter,
          storage_adapter: storage_adapter,
          id: id
        ).import!
      end
      output
    end

    class ResourceImporter
      attr_reader :bag_storage_adapter, :bag_metadata_adapter, :metadata_adapter, :storage_adapter, :id
      def initialize(bag_metadata_adapter:, bag_storage_adapter:, metadata_adapter:, storage_adapter:, id:)
        @bag_metadata_adapter = bag_metadata_adapter
        @bag_storage_adapter = bag_storage_adapter
        @metadata_adapter = metadata_adapter
        @storage_adapter = storage_adapter
        @id = id
      end

      def import!
        file_identifiers.each do |file_identifier|
          file = IngestableFile.new(bag_storage_adapter.find_by(id: file_identifier))
          migrated_file = storage_adapter.upload(file: file, original_filename: bag_original_file.original_filename.first, resource: bag_resource)
          bag_resource.original_file.file_identifiers = [migrated_file.id]
        end
        resource = metadata_adapter.persister.save(resource: bag_resource)
        import_members!
        resource
      end

      class IngestableFile < SimpleDelegator
        def path
          disk_path
        end
      end

      def import_members!
        member_ids.each do |member_id|
          ResourceImporter.new(
            bag_storage_adapter: bag_storage_adapter,
            bag_metadata_adapter: member_bag_metadata_adapter,
            metadata_adapter: metadata_adapter,
            storage_adapter: storage_adapter,
            id: member_id
          ).import!
        end
      end

      def member_ids
        bag_resource.try(:member_ids) || []
      end

      def bag_original_file
        bag_resource.try(:original_file)
      end

      def file_identifiers
        bag_original_file.try(:file_identifiers) || []
      end

      def member_bag_metadata_adapter
        return bag_metadata_adapter if bag_metadata_adapter.nested?
        bag_metadata_adapter.for(bag_id: id)
      end

      def bag_resource
        @bag_resource ||= bag_metadata_adapter.query_service.find_by(id: id)
      end
    end
  end
end
