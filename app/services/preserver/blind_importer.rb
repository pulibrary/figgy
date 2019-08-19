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
  delegate :storage_adapter, to: :change_set_persister
  def initialize(id:, importing_metadata_adapter:)
    @id = id
    @importing_metadata_adapter = importing_metadata_adapter
  end

  def import!
    import_file_identifiers
    member_ids = importing_resource.try(:member_ids) || []
    member_ids.map! do |member_id|
      begin
        output = self.class.import(id: member_id, importing_metadata_adapter: importing_metadata_adapter.with_parent(parent: importing_resource))
        if output.is_a?(FileSet)
          importing_change_set.created_file_sets += [output]
        end
        output.id
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end
    end.compact!
    output = change_set_persister.save(change_set: importing_change_set)
    output
  end

  def import_file_identifiers
    return unless importing_resource.try(:file_metadata).present?
    importing_resource.file_metadata.each do |file_metadata|
      file_metadata.file_identifiers.map! do |file_identifier|
        file = importing_storage_adapter.find_by(id: file_identifier)
        disk_path = file.disk_path
        uploaded_file = storage_adapter.upload(
          file: File.open(disk_path),
          original_filename: file_metadata.original_filename.first,
          resource: file_metadata
        )
        uploaded_file.id
      end
    end
  end

  def importing_resource
    @importing_resource ||= importing_metadata_adapter.query_service.find_by(id: id)
  end

  def importing_change_set
    @change_set ||= DynamicChangeSet.new(importing_resource)
  end

  def importing_storage_adapter
    importing_metadata_adapter.storage_adapter
  end

  def change_set_persister
    ScannedResourcesController.change_set_persister
  end
end
