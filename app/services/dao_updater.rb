# frozen_string_literal: true

class DaoUpdater
  attr_reader :change_set, :change_set_persister
  def initialize(change_set:, change_set_persister:)
    @change_set = change_set
    @change_set_persister = change_set_persister
  end

  def update!
    return unless decorated_resource.public_readable_state?
    return if decorated_resource.private_visibility?

    # Assign digital object to Archival Object.
    link_digital_object
  rescue Aspace::Client::ArchivalObjectNotFound
    Honeybadger.notify(
      "DaoUpdater failed to update resource #{change_set.id} with source metadata identifier #{change_set.source_metadata_identifier}." \
      "If the source metadata identifier looks like a component id (e.g. MC001), talk to the product owner." \
      "Otherwise, ask on #figgy whether anyone recognizes what's going on"
    )
  end

  def archival_object
    @archival_object ||= aspace_client.find_archival_object_by_component_id(component_id: change_set.source_metadata_identifier)
  end

  def digital_object
    @digital_object ||= update_or_create_digital_object
  end

  def decorated_resource
    @decorated_resource ||= change_set.resource.decorate
  end

  # Add a new instance to the existing Archival Object to link the new digital
  # object to it.
  def link_digital_object
    payload = archival_object.source
    payload["instances"] = archival_object.non_figgy_instances
    payload["instances"] += [new_instance]
    aspace_client.post(archival_object.uri, payload.to_json)
  end

  def new_instance
    {
      "instance_type" => "digital_object",
      "jsonmodel_type" => "instance",
      "is_representative" => false,
      "digital_object" => { "ref" => digital_object["uri"] }
    }
  end

  def update_or_create_digital_object
    found = aspace_client.get("/repositories/#{archival_object.repository_id}/find_by_id/digital_objects?digital_object_id[]=#{change_set.resource.id}&resolve[]=digital_objects").parsed
    found = found["digital_objects"].first&.fetch("_resolved")
    return update_digital_object(found) if found
    create_digital_object
  end

  def update_digital_object(found_digital_object)
    aspace_client.post(found_digital_object["uri"], new_dao.merge("lock_version" => found_digital_object["lock_version"]).to_json).parsed
  end

  def create_digital_object
    result = aspace_client.post("/repositories/#{archival_object.repository_id}/digital_objects", new_dao.to_json)
    result.parsed
  end

  def new_dao
    if zip_file?
      zip_file_dao
    else
      manifest_dao
    end
  end

  def zip_file?
    (file_set&.mime_type || []).include?("application/zip")
  end

  def manifest_dao
    {
      "jsonmodel_type" => "digital_object_component",
      "digital_object_id" => change_set.id.to_s,
      "title" => "View digital content",
      "publish" => true,
      "file_versions" => [
        {
          "file_uri" => ManifestBuilder::ManifestHelper.new.manifest_url(change_set.resource),
          "publish" => true,
          "jsonmodel_type" => "file_version",
          "use_statement" => "https://iiif.io/api/presentation/2.1/"
        }
      ]
    }
  end

  def file_set
    @file_set ||= Wayfinder.for(change_set.resource).file_sets.first
  end

  def zip_file_dao
    {
      "jsonmodel_type" => "digital_object_component",
      "digital_object_id" => change_set.id.to_s,
      "title" => "View digital content",
      "publish" => true,
      "file_versions" => [
        {
          "file_uri" => ManifestBuilder::ManifestHelper.new.download_url(file_set.id, file_set.primary_file.id),
          "publish" => true,
          "jsonmodel_type" => "file_version"
        }
      ]
    }
  end

  def aspace_client
    @aspace_client ||= Aspace::Client.new
  end
end
