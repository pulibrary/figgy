# frozen_string_literal: true

class DaoUpdater
  attr_reader :change_set, :change_set_persister
  def initialize(change_set:, change_set_persister:)
    @change_set = change_set
    @change_set_persister = change_set_persister
  end

  def update!
    archival_object = aspace_client.find_archival_object_by_component_id(component_id: change_set.source_metadata_identifier)

    # Create digital object.
    digital_object = create_digital_object(archival_object)
    # Assign digital object to Archival Object.
    link_digital_object(archival_object: archival_object, digital_object: digital_object)
  end

  # Add a new instance to the existing Archival Object to link the new digital
  # object to it.
  def link_digital_object(archival_object:, digital_object:)
    instance = new_instance(digital_object["uri"])
    payload = archival_object.source
    payload["instances"] = archival_object.non_figgy_instances
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
