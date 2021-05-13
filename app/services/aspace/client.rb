# frozen_string_literal: true
module Aspace
  class Client < ArchivesSpace::Client
    def self.config
      ArchivesSpace::Configuration.new(
        {
          base_uri: Figgy.config["archivespace_url"],
          username: Figgy.config["archivespace_user"],
          password: Figgy.config["archivespace_password"],
          page_size: 50,
          throttle: 0
        }
      )
    end

    def initialize
      super(self.class.config)
      login
    end

    def find_archival_object_by_component_id(component_id:)
      # Check every repository, we don't store things by repository in Figgy.
      repositories.each do |repository|
        archival_object = get("#{repository["uri"]}/find_by_id/archival_objects?ref_id[]=#{component_id}").parsed
      end
    end
  end
end
