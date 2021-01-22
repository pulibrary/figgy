# frozen_string_literal: true
module PulMetadataServices
  class AspacePulfaRecord
    attr_reader :source
    def initialize(source)
      @source = source
    end

    def attributes
      @attributes ||= JSON.parse(source, symbolize_names: true)
    end

    def full_source
      source
    end
  end
end
