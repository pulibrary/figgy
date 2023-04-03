# frozen_string_literal: true
module Bagit
  class MetadataAdapter
    attr_reader :base_path
    def initialize(base_path:)
      @base_path = Pathname.new(base_path.to_s)
    end

    def persister
      @persister ||= Bagit::Persister.new(adapter: self)
    end

    def bag_factory
      @bag_factory ||= Bagit::BagFactory.new(adapter: self)
    end

    def query_service
      @query_service ||= Bagit::QueryService.new(adapter: self)
    end

    def bag_paths
      Dir.glob(base_path.join("*"))
    end

    def for(bag_id:)
      NestedMetadataAdapter.new(base_path: base_path, bag_id: bag_id)
    end

    def nested?
      false
    end

    def bag_path(id:)
      base_path.join(id.to_s)
    end

    def id
      @id ||= Valkyrie::ID.new(Digest::MD5.hexdigest("bagit://#{base_path}"))
    end

    class NestedMetadataAdapter < Bagit::MetadataAdapter
      attr_reader :base_path, :bag_id
      def initialize(base_path:, bag_id:)
        @base_path = base_path
        @bag_id = bag_id
      end

      def bag_path(id:)
        base_path.join(bag_id.to_s)
      end

      def nested?
        true
      end
    end
  end
end
