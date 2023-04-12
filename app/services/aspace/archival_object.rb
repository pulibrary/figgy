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
        digital_objects.map do |digital_object|
          aspace_client.find_digital_object_by_ref(ref: digital_object["digital_object"]["ref"])
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

    def aspace_client
      @aspace_client ||= Aspace::Client.new
    end
  end
end
