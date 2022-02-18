# frozen_string_literal: true

module Bagit
  class BagLoader
    attr_reader :adapter, :id
    delegate :base_path, to: :adapter
    def initialize(adapter:, id:)
      @adapter = adapter
      @id = id
    end

    def load!
      resource_klass.new(converted_attributes.merge(new_record: false))
    end

    def exist?
      File.exist?(metadata_path)
    end

    private

      def bag_path
        @bag_path ||= adapter.bag_path(id: id)
      end

      def converted_attributes
        @converted_attributes ||= Valkyrie::Persistence::Postgres::ORMConverter::RDFMetadata.new(attributes).result.symbolize_keys
      end

      def attributes
        @resource_metadata ||= JSON.parse(File.read(bag_path.join("metadata", "#{id}.jsonld")))
      end

      def metadata_path
        bag_path.join("metadata", "#{id}.jsonld")
      end

      def internal_resource
        attributes["internal_resource"]
      end

      def resource_klass
        internal_resource.constantize
      end
  end
end
