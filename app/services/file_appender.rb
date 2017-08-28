# frozen_string_literal: true
class FileAppender
  attr_reader :storage_adapter, :persister, :files
  def initialize(storage_adapter:, persister:, files:)
    @storage_adapter = storage_adapter
    @persister = persister
    @files = files
  end

  def append_to(resource)
    return [] if files.blank?
    updated_files = update_files(resource, files)
    return updated_files unless updated_files.empty?

    file_sets = build_file_sets || file_nodes
    if file_set?(resource)
      resource.file_metadata += file_sets
    else
      resource.member_ids += file_sets.map(&:id)
      resource.thumbnail_id = file_sets.first.id if resource.thumbnail_id.blank?
    end
    adjust_pending_uploads(resource)
    file_sets
  end

  def file_set?(resource)
    resource.respond_to?(:file_metadata) && !resource.respond_to?(:member_ids)
  end

  def update_files(resource, files)
    files.select { |file| file.is_a?(Hash) }.map do |file|
      node = resource.file_metadata.select { |x| x.id.to_s == file.keys.first }.first
      file_wrapper = UploadDecorator.new(file.values.first, node.original_filename.first)
      file = storage_adapter.upload(file: file_wrapper, resource: node)
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
    file = storage_adapter.upload(file: file, resource: node)
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
end
