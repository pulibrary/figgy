module Aspace
  class DigitalObject
    attr_reader :source
    def initialize(source)
      @source = source
    end

    def linked_to_figgy?
      source["file_versions"].find do |version|
        version["file_uri"].include?("figgy")
      end
    end
  end
end
