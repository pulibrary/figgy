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
    file_sets = build_file_sets || file_nodes
    resource.member_ids = resource.member_ids + file_sets.map(&:id)
    adjust_pending_uploads(resource)
    file_sets
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
    resource.pending_uploads = (resource.pending_uploads || []) - files
  end

  def processing_derivatives?
    !file_nodes.first.use.include?(Valkyrie::Vocab::PCDMUse.OriginalFile)
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
    node = persister.save(resource: FileMetadata.for(file: file))
    file = storage_adapter.upload(file: file, resource: node)
    node.file_identifiers = node.file_identifiers + [file.id]
    persister.save(resource: node)
  end

  def create_file_set(file_node, file)
    attributes = {
      title: file_node.original_filename,
      member_ids: file_node.id
    }.merge(
      file.try(:container_attributes) || {}
    )
    persister.save(resource: FileSet.new(attributes))
  end
end
