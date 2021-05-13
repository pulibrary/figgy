# frozen_string_literal: true
class ChangeSetPersister
  class UpdateAspaceDao
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless pulfa_record?
      return unless recently_published?
      archival_object = aspace_client.find_archival_object_by_component_id(component_id: change_set.source_metadata_identifier)
      return if archival_object.manifest?(source_metadata_identifier: change_set.source_metadata_identifier)

      # Create digital object.
      digital_object = create_digital_object(archival_object)
      # Assign digital object to Archival Object.
      link_digital_object(archival_object: archival_object, digital_object: digital_object)
    end

    def link_digital_object(archival_object:, digital_object:)
      instance = new_instance(digital_object["uri"])
      payload = archival_object.source
      payload["instances"] += [instance]
      aspace_client.post(archival_object.uri, payload)
    end

    def new_instance(dao_uri)
      {
        "instance_type" => "digital_object",
        "jsonmodel_type" => "instance",
        "is_representative" => false,
        "digital_object" => { "ref" => dao_uri }
      }
    end

    def create_digital_object(archival_object)
      result = aspace_client.post("/repositories/#{archival_object.repository_id}/digital_objects", new_dao)
      result.parsed
    end

    def new_dao
      {
        "jsonmodel_type" => "digital_object_component",
        "digital_object_id" => change_set.id.to_s,
        "title" => "View digital content",
        "publish" => true,
        "file_versions" => [
          {
            "file_uri" => "https://figgy.princeton.edu/concern/scanned_resources/#{change_set.id}/manifest",
            "publish" => true,
            "jsonmodel_type" => "file_version"
          }
        ]
      }
    end

    def recently_published?
      change_set.changed?(:state) && change_set.resource.decorate.public_readable_state?
    end

    def pulfa_record?
      RemoteRecord.pulfa?(change_set.try(:source_metadata_identifier).to_s)
    end

    def aspace_client
      @aspace_client ||= Aspace::Client.new
    end
  end
end
