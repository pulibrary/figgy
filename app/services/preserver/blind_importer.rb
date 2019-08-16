# frozen_string_literal: true
class Preserver::BlindImporter
  def self.import(id:, importing_metadata_adapter: default_importing_metadata_adapter)
    new(id: id, importing_metadata_adapter: importing_metadata_adapter).import!
  end

  def self.default_importing_metadata_adapter
    FileMetadataAdapter.new(storage_adapter: importing_storage_adapter)
  end

  def self.importing_storage_adapter
    Valkyrie::StorageAdapter.find(:google_cloud_storage)
  end

  attr_reader :id, :importing_metadata_adapter
  def initialize(id:, importing_metadata_adapter:)
    @id = id
    @importing_metadata_adapter = importing_metadata_adapter
  end

  def import!
    output = change_set_persister.save(change_set: importing_change_set)
    member_ids = output.try(:member_ids) || []
    member_ids.each do |member_id|
      self.class.import(id: member_id, importing_metadata_adapter: importing_metadata_adapter.with_parent(parent: output))
    end
    output
  end

  def importing_resource
    @importing_resource ||= importing_metadata_adapter.query_service.find_by(id: id)
  end

  def importing_change_set
    @change_set ||= DynamicChangeSet.new(importing_resource)
  end

  def change_set_persister
    ScannedResourcesController.change_set_persister
  end
end
