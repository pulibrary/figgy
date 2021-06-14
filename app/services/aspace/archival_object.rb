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

    def resolved_digital_objects
      @resolved_digital_objects ||=
        begin
          digital_objects.map do |digital_object|
            aspace_client.find_digital_object_by_ref(ref: digital_object["digital_object"]["ref"])
          end
        end
    end

    def figgy_objects
      resolved_digital_objects.select(&:linked_to_figgy?)
    end

    def non_figgy_instances
      source["instances"].select do |instance|
        instance["instance_type"] != "digital_object" || !figgy_objects.map(&:uri).include?(instance["digital_object"]["ref"])
      end
    end

    def existing_figgy_digital_object
      digital_objects.find do |digital_object|
        resolved = aspace_client.find_digital_object_by_ref(ref: digital_object["digital_object"]["ref"])
        resolved.linked_to_figgy?
      end
    end

    def manifest?(source_metadata_identifier:)
      existing_figgy_digital_object.present?
    end

    def aspace_client
      @aspace_client ||= Aspace::Client.new
    end
  end
end
