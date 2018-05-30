# frozen_string_literal: true
# Creates file sets to be added to resources via a changeset
class FileAppender
  attr_reader :storage_adapter, :persister, :files

  # files must respond to:
  #   #path, #content_type, and #original_filename
  def initialize(storage_adapter:, persister:, files:)
    @storage_adapter = storage_adapter
    @persister = persister
    @files = files
  end

  def file_set?(resource)
    ResourceDetector.file_set?(resource)
  end

  def viewable_resource?(resource)
    ResourceDetector.viewable_resource?(resource)
  end

  def append_to(resource)
    return [] if files.empty?
    updated_files = update_files(resource)
    return updated_files unless updated_files.empty?
    file_resources = FileResources.new(build_file_sets || file_nodes)
    resource.file_metadata += file_resources.file_metadata if file_set?(resource)
    if viewable_resource?(resource)
      resource.member_ids += file_resources.ids
      # Set the thumbnail id if a valid file resource is found
      thumbnail_id = find_thumbnail_id(resource, file_resources)
      resource.thumbnail_id = thumbnail_id if thumbnail_id
    end
    adjust_pending_uploads(resource)
    file_resources
  end

  def update_files(resource)
    files.select { |file| file.is_a?(Hash) }.map do |file|
      node = resource.file_metadata.select { |x| x.id.to_s == file.keys.first }.first
      node.updated_at = Time.current
      file_wrapper = UploadDecorator.new(file.values.first, node.original_filename.first)

      node.label = file.values.first.original_filename
      node.mime_type = file.values.first.content_type
      storage_adapter.upload(file: file_wrapper, original_filename: file_wrapper.original_filename, resource: node)
      node
    end
  end

  def build_file_sets
    return if processing_derivatives?
    file_nodes.each_with_index.map do |node, index|
      file_set = create_file_set(node, files[index])
      file_set
    end
  end

  def adjust_pending_uploads(resource)
    return unless resource.respond_to?(:pending_uploads)
    resource.pending_uploads = [] if resource.pending_uploads.blank?
    resource.pending_uploads = (resource.pending_uploads || []) - files
  end

  def processing_derivatives?
    !file_nodes.first.original_file?
  end

  def file_nodes
    @file_nodes ||=
      begin
        files.map do |file|
          create_node(file)
        end
      end
  end

  def create_node(file)
    attributes = {
      id: SecureRandom.uuid
    }.merge(
      file.try(:node_attributes) || {}
    )
    node = FileMetadata.for(file: file).new(attributes)
    file = storage_adapter.upload(file: file, resource: node, original_filename: file.original_filename)
    node.file_identifiers = node.file_identifiers + [file.id]
    node
  end

  def create_file_set(file_node, file)
    attributes = {
      title: file_node.original_filename,
      file_metadata: [file_node]
    }.merge(
      file.try(:container_attributes) || {}
    )
    persister.save(resource: FileSet.new(attributes))
  end

  # Returns a thumbnail id for a resource and a array of file_resources.
  def find_thumbnail_id(resource, file_resources)
    return unless resource.thumbnail_id.blank?
    file_resources.each do |file_resource|
      extension = File.extname(file_resource.original_file.original_filename.first)
      return file_resource.id unless no_thumbail_extensions.include?(extension)
    end

    nil
  end

  # Extensions for original_files that shouldn't be used as thumbnails.
  def no_thumbail_extensions
    [".xml"]
  end
end
