# frozen_string_literal: true

module Aspace
  class ArchivalObject
    attr_reader :source
    def initialize(source)
      @source = source
    end

    def repository_id
      source["repository"]["ref"].split("/").last
    end

    def uri
      source["uri"]
    end

    def digital_objects
      source["instances"].select do |instance|
        instance["instance_type"] == "digital_object"
      end
    end

    def existing_figgy_digital_object
      digital_objects.find do |digital_object|
        resolved = aspace_client.find_digital_object_by_ref(ref: digital_object["digital_object"]["ref"])
        resolved.linked_to_figgy?
      end
    end

    # TODO: Implement this. It should check instances for digital objects which
    # correspond to the given figgy manifest.
    def manifest?(source_metadata_identifier:)
      existing_figgy_digital_object.present?
    end

    def aspace_client
      @aspace_client ||= Aspace::Client.new
    end
  end
end
