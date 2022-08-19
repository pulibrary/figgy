# frozen_string_literal: true
# Creates file sets to be added to resources via a changeset
class FileAppender
  attr_reader :files, :parent
  attr_reader :change_set_persister
  delegate :storage_adapter, to: :change_set_persister

  # Constructor
  # @param change_set_persister
  # @param files [Array<Object>] the files being updated or created for the resource being changed
  # @param parent [Resource] the resource being appended to
  # files must respond to:
  #   #path, #content_type, and #original_filename
  def initialize(files:, parent:, change_set_persister:)
    @files = files
    @parent = parent
    @change_set_persister = change_set_persister
  end

  # Append FileNodes to the parent
  # @return [Array<FileNode>] the updated or newly created FileNodes
  def append
    return [] if files.empty?
    if file_set?(parent)
      file_set_append
    else
      resource_append
    end
  end

  def resource_append
    file_sets = build_file_sets

    # If parent can be viewed (e. g. has thumbnails), retrieve and set its thumbnail ID to the appropriate FileNode
    if viewable_parent?
      parent.member_ids += file_sets.map(&:id)
      # Set the thumbnail id if a valid file resource is found
      thumbnail_id = find_thumbnail_id(file_sets)
      parent.thumbnail_id = thumbnail_id if thumbnail_id
    end

    # Update the state of the pending uploads for parent
    adjust_pending_uploads

    file_sets
  end

  # A use case: adding derivatives to file sets
  def file_set_append
    # Append the array of file metadata values to any FileSets with new FileNodes being appended
    parent.file_metadata += file_nodes
    file_nodes
  end

  private

    # Generate a title for a FileSet based on parent class
    # @param filename [String]
    # @return [String] title
    def fileset_title(filename)
      case parent
      when Numismatics::Coin
        coin_image_title(filename)
      else
        filename
      end
    end

    # Generate a title for a Coin FileSet
    # @param filename [String]
    # @return [String] title
    def coin_image_title(filename)
      if /R/.match?(filename)
        "Reverse"
      elsif /O/.match?(filename)
        "Obverse"
      else
        filename
      end
    end

    # Create and persist a FileSet Resource using a file
    # @param file_node [File]
    # @param file [File]
    # @return [FileSet] the newly persisted FileSet Resource
    def create_file_set(file_node, file)
      attributes = {
        title: fileset_title(file_node.original_filename.first),
        file_metadata: [file_node],
        processing_status: "in process"
      }.merge(
        file.try(:container_attributes) || {}
      )
      file_set = FileSet.new(attributes)
      change_set = ChangeSet.for(file_set)
      change_set_persister.save(change_set: change_set)
    end

    # Constructs FileSet Objects using the files being uploaded
    # Does *not* construct new Objects if derivatives are being processed
    # @return [Array<FileSet>]
    def build_file_sets
      return [] if file_nodes.empty?
      file_nodes.each_with_index.map do |node, index|
        file_set = create_file_set(node, files[index])
        file_set
      end
    end

    # Create and persist FileMetadata nodes for a given file
    # @param file [PendingUpload] the file being persisted
    # @return [FileMetadata] the newly-persisted FileMetadata node
    def create_node(file)
      attributes = {
        id: SecureRandom.uuid
      }.merge(
        file.try(:node_attributes) || {}
      )
      node = FileMetadata.for(file: file).new(attributes)
      original_filename = file.original_filename
      upload_options = file.try(:upload_options) || {}
      stored_file = storage_adapter.upload(file: file, resource: node, original_filename: original_filename, **upload_options)
      file.try(:close)
      node.file_identifiers = node.file_identifiers + [stored_file.id]
      node
    rescue StandardError => error
      message = "#{self.class}: Failed to append the new file #{original_filename} for #{node.id} to resource #{parent.id}: #{error}"
      Valkyrie.logger.error message
      Honeybadger.notify message
      nil
    end

    # Create or retrieve the memoized FileMetadata nodes for new files
    # @return [Array<FileMetadata>]
    def file_nodes
      @file_nodes ||= files.map { |file| create_node(file) }.compact
    end

    # Determines if the resource being changed is a FileSet
    # @param resource [Resource]
    # @return [TrueClass, FalseClass]
    def file_set?(resource)
      resource.respond_to?(:file_metadata) && !resource.respond_to?(:member_ids)
    end

    # Determines if the parent is viewable
    # @return [TrueClass, FalseClass]
    def viewable_parent?
      parent.respond_to?(:member_ids) && parent.respond_to?(:thumbnail_id)
    end

    # Extensions for original_files that shouldn't be used as thumbnails.
    # @return [Array<String>] the file extensions
    def no_thumbnail_extensions
      [".xml", ".pdf"]
    end

    # Returns a thumbnail id for the parent and a array of file_sets.
    def find_thumbnail_id(file_sets)
      return if parent.thumbnail_id.present?
      file_sets.each do |file_set|
        extension = File.extname(file_set.primary_file.original_filename.first)
        return file_set.id unless no_thumbnail_extensions.include?(extension)
      end

      nil
    end

    # Remove or empty the pending uploads for the parent after the files have been persisted
    def adjust_pending_uploads
      return unless parent.respond_to?(:pending_uploads)
      parent.pending_uploads = [] if parent.pending_uploads.blank?
      parent.pending_uploads = (parent.pending_uploads || []) - files
    end
end
