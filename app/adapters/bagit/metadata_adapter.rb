# frozen_string_literal: true
module Bagit
  class MetadataAdapter
    attr_reader :base_path
    def initialize(base_path:)
      @base_path = base_path
    end

    def persister
      @persister ||= Bagit::Persister.new(adapter: self)
    end

    def bag_factory
      @bag_factory ||= Bagit::BagFactory.new(adapter: self)
    end

    def query_service; end
  end
end
