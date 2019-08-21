# frozen_string_literal: true
class Preserver::BlindImporter
  def self.import(id:, change_set_persister:, source_metadata_adapter: default_source_metadata_adapter)
    new(id: id, change_set_persister: change_set_persister, source_metadata_adapter: source_metadata_adapter).import!
  end

  def self.default_source_metadata_adapter
    FileMetadataAdapter.new(storage_adapter: source_storage_adapter)
  end

  def self.source_storage_adapter
    Valkyrie::StorageAdapter.find(:google_cloud_storage)
  end

  attr_reader :id, :source_metadata_adapter, :change_set_persister
  delegate :storage_adapter, to: :change_set_persister
  def initialize(id:, source_metadata_adapter:, change_set_persister:)
    @id = id
    @source_metadata_adapter = source_metadata_adapter
    @change_set_persister = change_set_persister
  end

  # Imports the given ID from the source metadata adapter as well as all its
  # children.
  def import!
    import_binary_files
    member_ids = source_resource.try(:member_ids) || []
    member_ids.map! do |member_id|
      begin
        member = self.class.import(id: member_id, source_metadata_adapter: source_metadata_adapter.with_context(parent: source_resource), change_set_persister: change_set_persister)
        source_change_set.created_file_sets += [member] if member.is_a?(FileSet)
        member.id
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end
    end.compact!
    output = change_set_persister.save(change_set: source_change_set)
    output
  end

  def import_binary_files
    return unless source_resource.try(:file_metadata).present?
    source_resource.file_metadata.each do |file_metadata|
      file_metadata.file_identifiers.map! do |file_identifier|
        file = source_storage_adapter.find_by(id: file_identifier)
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

  def source_resource
    @source_resource ||= source_metadata_adapter.query_service.find_by(id: id)
  end

  def source_change_set
    @change_set ||= DynamicChangeSet.new(source_resource)
  end

  def source_storage_adapter
    source_metadata_adapter.storage_adapter
  end
end
