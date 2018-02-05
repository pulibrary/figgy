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
  end
end
