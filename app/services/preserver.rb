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

  # Don't preserve children unless this is the first time it's being
  # preserved. After that point any updates to the children will trigger them
  # to preserve themselves, because their parent is set up to be.
  def preserve!
    preserve_binary_content
    if preservation_object.persisted?
      preserve_metadata
    else
      preserve_metadata && preserve_children
    end
  end

  def preserve_binary_content
    resource_binary_nodes.each do |resource_binary_node|
      next if !resource_binary_node.uploaded_content? || resource_binary_node.preserved?
      file_metadata = resource_binary_node.preservation_node
      uploaded_file = storage_adapter.upload(
        file: File.open(Valkyrie::StorageAdapter.find_by(id: resource_binary_node.file_identifiers.first).disk_path),
        original_filename: file_metadata.label.first,
        resource: resource
      )
      file_metadata.file_identifiers = uploaded_file.id
      preservation_object.binary_nodes += [file_metadata]
    end
  end

  def resource_binary_nodes
    [:original_files, :intermediate_files, :preservation_files].flat_map do |node_type|
      Array(resource[node_type]).map { |x| PreservationIntermediaryNode.new(binary_node: x, preservation_object: preservation_object) }
    end
  end

  def preservation_object
    @preservation_object ||=
      begin
        Wayfinder.for(resource).try(:preservation_object) || PreservationObject.new(preserved_object_id: resource.id)
      end
  end

  def preserve_children
    return unless resource.try(:member_ids).present?
    PreserveChildrenJob.perform_later(id: resource.id.to_s)
  end

  def preserve_metadata
    uploaded_file = storage_adapter.upload(file: temp_metadata_file.io, original_filename: metadata_node.label.first, resource: resource)
    metadata_node.file_identifiers = uploaded_file.id
    preservation_object.metadata_node = metadata_node
    change_set_persister.metadata_adapter.persister.save(resource: preservation_object)
  end

  def metadata_node
    @metadata_node ||=
      begin
        preservation_object.metadata_node ||
          FileMetadata.new(
            label: "#{resource.id}.json",
            mime_type: "application/json",
            checksum: MultiChecksum.for(temp_metadata_file),
            use: Valkyrie::Vocab::PCDMUse.PreservedMetadata
          )
      end
  end

  def temp_metadata_file
    @temp_metadata_file ||=
      begin
        file = Tempfile.new("#{resource.id}.json")
        file.write(resource.to_h.compact)
        file.rewind
        Valkyrie::StorageAdapter::File.new(io: file, id: "tmp")
      end
  end

  def default_storage_adapter
    Valkyrie::StorageAdapter.find(:google_cloud_storage)
  end
end
