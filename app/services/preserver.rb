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
    if preserve_children?
      preserve_metadata && preserve_children
    else
      preserve_metadata
    end
  end

  private

    def preserve_children?
      @created_preservation_object == true
    end

    def preserve_binary_content(force: false)
      # Initialize so it saves early - if two Preservers are running at the
      # same time somehow, this will make one of them error with a database
      # constraint error before uploading anything.
      preservation_object
      # These are PreservationIntermediaryNodes
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
      f = File.open(Valkyrie::StorageAdapter.find_by(id: resource_binary_node.file_identifiers.first).disk_path)
      uploaded_file = storage_adapter.upload(
        file: f,
        original_filename: file_metadata.label.first,
        resource: resource,
        md5: local_md5_checksum,
        metadata: preservation_metadata
      )
      f.close
      file_metadata.checksum = resource_binary_node.calculate_checksum
      # The FileSet or its parent resource has moved and is now under a different resource hierarchy
      if file_metadata.file_identifiers.present? && !file_metadata.file_identifiers.include?(uploaded_file.id)
        CleanupFilesJob.perform_later(file_identifiers: file_metadata.file_identifiers.map(&:to_s))
      end
      file_metadata.file_identifiers = uploaded_file.id
      # the preservation object is saved after the metdata_node is added
      preservation_object.binary_nodes += [file_metadata] unless file_metadata.persisted?
      # mark it as persisted for future checks
      file_metadata.new_record = false
    end

    def resource_binary_nodes
      [:original_files, :intermediate_files, :preservation_files].flat_map do |node_type|
        Array(resource.try(node_type)).map { |x| PreservationIntermediaryNode.new(binary_node: x, preservation_object: preservation_object) }
      end
    end

    def preservation_object
      @preservation_object ||=
        begin
          Wayfinder.for(resource).try(:preservation_object) || create_preservation_object
        end
    end

    def create_preservation_object
      @created_preservation_object = true
      change_set_persister.persister.save(resource: PreservationObject.new(preserved_object_id: resource.id))
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
      temp_metadata_file.io.close
      metadata_node.file_identifiers = uploaded_file.id
      # if metadata file has been saved to google cloud and that location is not
      # (location is the filename / path)
      # the location of the file that we just uploaded
      # The name of the metadata file does not change, so if it wasn't in this
      # location before, that indicates that resources have been reorganized.

      # If I move a resource to be the child of another resource, all of its
      # nested resources also need to be moved.
      # e.g. I moved /1/a/metadata.json to /2/a/metadata.json
      if preservation_object.metadata_node&.file_identifiers.present? && preservation_object.metadata_node.file_identifiers[0] != uploaded_file.id
        # Parent structure has changed, re-preserve children.
        preserve_children
        preserve_binary_content(force: true)
        # clean up the old files, e.g. /1/a/metadata.json from example above
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
        begin
          FileMetadata.new(
            label: "#{resource.id}.json",
            mime_type: "application/json",
            checksum: MultiChecksum.for(temp_metadata_file),
            use: Valkyrie::Vocab::PCDMUse.PreservedMetadata,
            id: SecureRandom.uuid
          )
        end
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
