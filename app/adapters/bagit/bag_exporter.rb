# frozen_string_literal: true
module Bagit
  class BagExporter
    attr_reader :metadata_adapter, :storage_adapter, :query_service
    def initialize(metadata_adapter:, storage_adapter:, query_service:)
      @metadata_adapter = metadata_adapter
      @storage_adapter = storage_adapter
      @query_service = query_service
    end

    def export(resource:)
      ResourceExporter.new(
        metadata_adapter: metadata_adapter,
        storage_adapter: storage_adapter.for(bag_id: resource.id),
        resource: resource,
        query_service: query_service
      ).export!
    end

    class ResourceExporter
      attr_reader :metadata_adapter, :storage_adapter, :resource, :query_service
      def initialize(metadata_adapter:, storage_adapter:, resource:, query_service:)
        @metadata_adapter = metadata_adapter
        @storage_adapter = storage_adapter
        @query_service = query_service
        @resource = resource
      end

      def export!
        file_identifiers.each do |file_identifier|
          file = Valkyrie::StorageAdapter.find_by(id: file_identifier)
          bag_file = storage_adapter.upload(file: file, original_filename: original_file.original_filename.first, resource: resource)
          resource.original_file.file_identifiers = [bag_file.id]
        end
        metadata_adapter.persister.save(resource: resource)
        members.each do |member|
          self.class.new(
            metadata_adapter: member_metadata_adapter,
            storage_adapter: storage_adapter,
            resource: member,
            query_service: query_service
          ).export!
        end
      end

      def original_file
        resource.try(:original_file)
      end

      def file_identifiers
        original_file.try(:file_identifiers) || []
      end

      def member_metadata_adapter
        return metadata_adapter if metadata_adapter.nested?
        metadata_adapter.for(bag_id: resource.id)
      end

      def members
        @members ||= query_service.find_members(resource: resource)
      end
    end
  end
end
