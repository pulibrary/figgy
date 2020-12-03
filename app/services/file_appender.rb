# frozen_string_literal: true
# Creates file sets to be added to resources via a changeset
class FileAppender
  # Class for capturing file creation errors
  class CreateFileError < StandardError; end

  # Class for capturing file upload errors
  class UpdateFileError < StandardError; end

  attr_reader :files
  attr_reader :change_set_persister
  delegate :storage_adapter, to: :change_set_persister

  # Constructor
  # @param change_set_persister
  # @param files [Array<Object>] the files being updated or created for the resource being changed
  # files must respond to:
  #   #path, #content_type, and #original_filename
  def initialize(files:, change_set_persister:)
    @files = files
    @change_set_persister = change_set_persister
  end

  # Append FileNodes to a given resource
  # @param resource [Resource]
  # @return [Array<FileNode>] the updated or newly created FileNodes
  def append_to(resource)
    return [] if files.empty?
    return file_set_append_to(resource) if file_set?(resource)
    resource_append_to(resource)
  end

  private

    def resource_append_to(resource)
      # Update the files for the resource if they have already been appended
      # updated_files = update_files(resource)
      # return updated_files unless updated_files.empty?
      #
      file_sets = build_file_sets(resource)

      # If this resource can be viewed (e. g. has thumbnails), retrieve and set the resource thumbnail ID to the appropriate FileNode
      if viewable_resource?(resource)
        resource.member_ids += file_sets.map(&:id)
        # Set the thumbnail id if a valid file resource is found
        thumbnail_id = find_thumbnail_id(resource, file_sets)
        resource.thumbnail_id = thumbnail_id if thumbnail_id
      end

      # Update the state of the pending uploads for this resource
      adjust_pending_uploads(resource)

      file_sets
    end

    # A use case: adding derivatives to file sets
    def file_set_append_to(resource)
      # Update the files for the resource if they have already been appended
      updated_files = update_files(resource)
      return updated_files unless updated_files.empty?

      # Append the array of file metadata values to any FileSets with new FileNodes being appended
      resource.file_metadata += file_nodes

      file_nodes
    end

    # Updates the files appended to a given resource
    # @param resource [Resource]
    # @return [Array<File>]
    def update_files(resource)
      updated = files.select { |file| file.is_a?(Hash) }.map do |file|
        node = resource.file_metadata.select { |x| x.id.to_s == file.keys.first.to_s }.first
        node.updated_at = Time.current
        # Uses the UploadDecorator to abstract the interface for the File Object during persistence by the storage_adapter
        file_wrapper = UploadDecorator.new(file.values.first, node.original_filename.first)

        # Ensure that errors for one file are logged but do not block updates for others
        begin
          storage_adapter.upload(file: file_wrapper, original_filename: file_wrapper.original_filename, resource: node)
          node.label = file.values.first.original_filename
          node.mime_type = file.values.first.content_type
          node
        rescue StandardError => error
          Valkyrie.logger.error "#{self.class}: Failed to update the file #{file_wrapper.original_filename} for #{node.id}: #{error}"
          # Ensure that this file is not created instead of updated
          @files.delete_if { |updated_file| updated_file.values.first.original_filename == file_wrapper.original_filename }
          nil
        end
      end

      updated.compact
    end

    # Generate a title for a FileSet based on resource class
    # @param resource [Resource]
    # @param filename [String]
    # @return [String] title
    def fileset_title(resource, filename)
      case resource
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
      if filename =~ /R/
        "Reverse"
      elsif filename =~ /O/
        "Obverse"
      else
        filename
      end
    end

    # Create and persist a FileSet Resource using a file
    # @param file_node [File]
    # @param file [File]
    # @return [FileSet] the newly persisted FileSet Resource
    def create_file_set(resource, file_node, file)
      attributes = {
        title: fileset_title(resource, file_node.original_filename.first),
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
    def build_file_sets(resource)
      return [] if file_nodes.empty?
      file_nodes.each_with_index.map do |node, index|
        file_set = create_file_set(resource, node, files[index])
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
      node.file_identifiers = node.file_identifiers + [stored_file.id]
      node
    rescue StandardError => error
      Valkyrie.logger.error "#{self.class}: Failed to append the new file #{original_filename} for #{node.id}: #{error}"
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

    # Determines if the resource being changed has a thumbnail
    # @param resource [Resource]
    # @return [TrueClass, FalseClass]
    def viewable_resource?(resource)
      resource.respond_to?(:member_ids) && resource.respond_to?(:thumbnail_id)
    end

    # Extensions for original_files that shouldn't be used as thumbnails.
    # @return [Array<String>] the file extensions
    def no_thumbnail_extensions
      [".xml", ".pdf"]
    end

    # Returns a thumbnail id for a resource and a array of file_sets.
    def find_thumbnail_id(resource, file_sets)
      return unless resource.thumbnail_id.blank?
      file_sets.each do |file_set|
        extension = File.extname(file_set.primary_file.original_filename.first)
        return file_set.id unless no_thumbnail_extensions.include?(extension)
      end

      nil
    end

    # Remove or empty the pending uploads for a resource after the files have been persisted
    # @param resource [Resource]
    def adjust_pending_uploads(resource)
      return unless resource.respond_to?(:pending_uploads)
      resource.pending_uploads = [] if resource.pending_uploads.blank?
      resource.pending_uploads = (resource.pending_uploads || []) - files
    end
end
