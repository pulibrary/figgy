# frozen_string_literal: true

class Preserver
  # Provided as a mechanism for switching preservation strategies depending on
  # the profile. For now, there's only one, so fall down to new.
  def self.for(change_set:, change_set_persister:, storage_adapter: nil)
    return NullPreserver unless change_set.try(:preserve?)
    new(change_set: change_set, change_set_persister: change_set_persister, storage_adapter: storage_adapter)
  end

  class NullPreserver
    def self.preserve!
    end
  end

  attr_reader :change_set, :storage_adapter, :change_set_persister
  delegate :resource, to: :change_set
  def initialize(change_set:, change_set_persister:, storage_adapter: nil)
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

  private

    def preserve_binary_content(force: false)
      resource_binary_nodes.each do |resource_binary_node|
        file_metadata = resource_binary_node.preservation_node
        next unless resource_binary_node.uploaded_content?
        preserve_binary_node(resource_binary_node, file_metadata) if force
        next if resource_binary_node.preserved?
        next if file_metadata.persisted?
        preserve_binary_node(resource_binary_node, file_metadata)
      end
    end

    def preserve_binary_node(resource_binary_node, file_metadata)
      local_checksum = file_metadata.checksum.first
      local_checksum_hex = [local_checksum.md5].pack("H*")
      local_md5_checksum = Base64.strict_encode64(local_checksum_hex)

      uploaded_file = storage_adapter.upload(
        file: File.open(Valkyrie::StorageAdapter.find_by(id: resource_binary_node.file_identifiers.first).disk_path),
        original_filename: file_metadata.label.first,
        resource: resource,
        md5: local_md5_checksum,
        metadata: preservation_metadata
      )
      file_metadata.checksum = resource_binary_node.calculate_checksum
      unless file_metadata.file_identifiers.empty? || file_metadata.file_identifiers.include?(uploaded_file.id)
        CleanupFilesJob.perform_later(file_identifiers: file_metadata.file_identifiers.map(&:to_s))
      end
      file_metadata.file_identifiers = uploaded_file.id
      preservation_object.binary_nodes += [file_metadata] unless file_metadata.persisted?
      file_metadata.new_record = false
    end

    def resource_binary_nodes
      [:original_files, :intermediate_files, :preservation_files].flat_map do |node_type|
        Array(resource.try(node_type)).map { |x| PreservationIntermediaryNode.new(binary_node: x, preservation_object: preservation_object) }
      end
    end

    def preservation_object
      @preservation_object ||=
        Wayfinder.for(resource).try(:preservation_object) || PreservationObject.new(preserved_object_id: resource.id)
    end

    def preserve_children
      return unless resource.try(:member_ids).present? && change_set.try(:preserve_children?)
      PreserveChildrenJob.perform_later(id: resource.id.to_s)
    end

    def preserve_metadata
      local_checksum = metadata_node.checksum.first
      local_checksum_hex = [local_checksum.md5].pack("H*")
      local_md5_checksum = Base64.strict_encode64(local_checksum_hex)

      uploaded_file = storage_adapter.upload(
        file: temp_metadata_file.io,
        original_filename: metadata_node.label.first,
        resource: resource,
        md5: local_md5_checksum,
        metadata: preservation_metadata
      )
      metadata_node.file_identifiers = uploaded_file.id
      if preservation_object.metadata_node&.file_identifiers.present? && preservation_object.metadata_node.file_identifiers[0] != uploaded_file.id
        # Parent structure has changed, re-preserve children.
        preserve_children
        preserve_binary_content(force: true)
        CleanupFilesJob.perform_later(file_identifiers: preservation_object.metadata_node.file_identifiers.map(&:to_s))
      end
      preservation_object.metadata_node = metadata_node
      change_set_persister.metadata_adapter.persister.save(resource: preservation_object)
    end

    def preservation_metadata
      {
        title: resource.try(:title)&.first,
        identifier: resource.try(:identifier)&.first,
        local_identifier: resource.try(:local_identifier)&.first,
        id: resource.id.to_s,
        source_metadata_identifier: resource.try(:source_metadata_identifier)&.first
      }
    end

    def metadata_node
      @metadata_node ||=
        FileMetadata.new(
          label: "#{resource.id}.json",
          mime_type: "application/json",
          checksum: MultiChecksum.for(temp_metadata_file),
          use: Valkyrie::Vocab::PCDMUse.PreservedMetadata,
          id: SecureRandom.uuid
        )
    end

    def temp_metadata_file
      @temp_metadata_file ||=
        begin
          file = Tempfile.new("#{resource.id}.json")
          file.write(resource.to_h.compact.to_json)
          file.rewind
          Valkyrie::StorageAdapter::File.new(io: file, id: "tmp")
        end
    end

    def default_storage_adapter
      Valkyrie::StorageAdapter.find(:google_cloud_storage)
    end
end
