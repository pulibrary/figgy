# frozen_string_literal: true
class Preserver
  # Provided as a mechanism for switching preservation strategies depending on
  # the profile. For now, there's only one, so fall down to new.
  def self.for(change_set:, change_set_persister:, storage_adapter: nil)
    return NullPreserver unless change_set.try(:preserve?)
    new(change_set: change_set, change_set_persister: change_set_persister, storage_adapter: storage_adapter)
  end

  class NullPreserver
    def self.preserve!; end
  end

  attr_reader :change_set, :storage_adapter, :change_set_persister
  delegate :resource, to: :change_set
  def initialize(change_set:, storage_adapter: nil, change_set_persister:)
    @change_set = change_set
    @storage_adapter = storage_adapter || default_storage_adapter
    @change_set_persister = change_set_persister
  end

  def preserve!
    preserve_original_file
    # Don't preserve children unless this is the first time it's being
    # preserved. After that point any updates to the children will trigger them
    # to preserve themselves, because their parent is set up to be.
    preserve_children unless already_preserved?
    preserve_metadata
  end

  def already_preserved?
    resource.try(:preservation_metadata).present?
  end

  def preserve_original_file
    return unless resource.try(:original_file) && resource.try(:preservation_copy).blank?
    file_metadata = FileMetadata.new(
      label: preservation_copy_label,
      use: Valkyrie::Vocab::PCDMUse.PreservationCopy,
      mime_type: resource.original_file.mime_type,
      checksum: resource.original_file.checksum
    )
    uploaded_file = storage_adapter.upload(
      file: File.open(Valkyrie::StorageAdapter.find_by(id: resource.original_file.file_identifiers.first).disk_path),
      original_filename: file_metadata.label.first,
      resource: resource
    )
    file_metadata.file_identifiers = uploaded_file.id
    resource.file_metadata += [file_metadata]
  end

  def preservation_copy_label
    label, splitter, extension = resource.original_file.label.first.rpartition(".")
    "#{label}-#{resource.original_file.id}#{splitter}#{extension}"
  end

  def preserve_children
    PreserveChildrenJob.perform_later(id: resource.id.to_s)
  end

  def preserve_metadata
    metadata_node = preserved_metadata_node || build_metadata_node
    uploaded_file = storage_adapter.upload(file: temp_metadata_file.io, original_filename: metadata_node.label.first, resource: resource)
    metadata_node.file_identifiers = uploaded_file.id
    resource.file_metadata += [metadata_node]
    change_set_persister.metadata_adapter.persister.save(resource: resource)
  end

  def metadata_checksum
    @metadata_checksum ||=
      begin
        io = StringIO.new(preservation_metadata.to_json)
        MultiChecksum.for(Valkyrie::StorageAdapter::File.new(io: io, id: "tmp"))
      end
  end

  # Don't preserve the PreservedMetadata FileMetadataNode, because it's
  # impossible to provide an identifier for the file it's referencing until it's
  # actually uploaded to the preservation backend.
  def preservation_metadata
    resource_hash = resource.to_h
    resource_hash[:file_metadata] = resource_hash[:file_metadata].select do |metadata|
      !metadata[:use].include?(Valkyrie::Vocab::PCDMUse.PreservedMetadata)
    end
    resource_hash.compact
  end

  def preserved_metadata_node
    resource.file_metadata.find do |file_metadata|
      file_metadata.use.include?(Valkyrie::Vocab::PCDMUse.PreservedMetadata)
    end
  end

  def build_metadata_node
    FileMetadata.new(
      label: "#{resource.id}.json",
      mime_type: "application/json",
      checksum: metadata_checksum,
      use: Valkyrie::Vocab::PCDMUse.PreservedMetadata
    )
  end

  def temp_metadata_file
    @temp_metadata_file ||=
      begin
        file = Tempfile.new("#{resource.id}.json")
        file.write(preservation_metadata.to_json)
        file.rewind
        Valkyrie::StorageAdapter::File.new(io: file, id: "tmp")
      end
  end

  def default_storage_adapter
    Valkyrie::StorageAdapter.find(:cloud_backup)
  end
end
