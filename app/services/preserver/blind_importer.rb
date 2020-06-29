# frozen_string_literal: true
class Preserver::BlindImporter
  def self.import(id: nil, source_resource: nil, change_set_persister:, source_metadata_adapter: default_source_metadata_adapter)
    new(id: id, source_resource: source_resource, change_set_persister: change_set_persister, source_metadata_adapter: source_metadata_adapter).import!
  end

  def self.default_source_metadata_adapter
    FileMetadataAdapter.new(storage_adapter: source_storage_adapter)
  end

  def self.source_storage_adapter
    Valkyrie::StorageAdapter.find(:google_cloud_storage)
  end

  attr_reader :id, :source_metadata_adapter, :change_set_persister
  delegate :storage_adapter, to: :change_set_persister
  def initialize(id: nil, source_metadata_adapter:, change_set_persister:, source_resource: nil)
    @id = id
    @source_metadata_adapter = source_metadata_adapter
    @change_set_persister = change_set_persister
    @source_resource = source_resource
  end

  # Imports the given ID from the source metadata adapter as well as all its
  # children.
  def import!
    import_binary_files
    member_ids = []
    source_metadata_adapter.query_service.find_members(resource: source_resource).each do |member|
      member = self.class.import(source_resource: member, source_metadata_adapter: source_metadata_adapter, change_set_persister: change_set_persister)
      source_change_set.created_file_sets += [member] if member.is_a?(FileSet)
      member_ids << member.id
    end
    # Get rid of non-preserved members.
    source_change_set.try(:member_ids=, member_ids)
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
    @change_set ||= ChangeSet.for(source_resource)
  end

  def source_storage_adapter
    source_metadata_adapter.storage_adapter
  end
end
