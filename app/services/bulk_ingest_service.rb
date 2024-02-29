# frozen_string_literal: true
class BulkIngestService
  attr_reader :change_set_persister, :logger, :change_set_param
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter
  def initialize(change_set_persister:, klass: ScannedResource, change_set_param: nil, logger: Valkyrie.logger)
    @change_set_persister = change_set_persister
    @klass = klass
    @change_set_param = change_set_param
    @logger = logger
  end

  # Iterate through a list of directories and attach the files within each
  # @param base_directory [String] the path to the parent directory
  # @param property [String, nil] the resource property (when attaching files to existing resources)
  # @param file_filters [Array] the filter used for matching against the filename extension
  def attach_each_dir(base_directory:, property: nil, file_filters: [], preserve_file_names: false, **attributes)
    raise ArgumentError, "#{self.class}: Directory does not exist: #{base_directory}" unless File.exist?(base_directory)

    entries = Dir["#{base_directory}/*"]
    raise ArgumentError, "#{self.class}: Directory is empty: #{base_directory}" if entries.empty?
    entries.sort.each do |subdir|
      next unless File.directory?(subdir)
      logger.info "Attaching #{subdir}"
      attach_dir(base_directory: subdir, property: property, file_filters: file_filters, preserve_file_names: preserve_file_names, **attributes)
    end
  end

  # Attach files within a directory
  # This may attach to existing resources (such as EphemeraFolder objects) using a property (e. g. "barcode")
  # This may also create new resources (such as ScannedResource objects)
  # @param base_directory [String] the path to the base directory
  # @param property [String, nil] the resource property (when attaching files to existing resources)
  # @param file_filters [Array] the filter used for matching against the filename extension
  def attach_dir(base_directory:, property: nil, file_filters: [], preserve_file_names: false, **attributes)
    raise ArgumentError, "#{self.class}: Directory does not exist: #{base_directory}" unless File.exist?(base_directory)
    return ingest_bag(base_directory: base_directory, **attributes) if archival_media_bag?(base_directory)

    file_entries = Dir["#{base_directory}/*"]
    # Filter for hidden files
    entries = file_entries.reject { |entry| entry =~ /^\..+/ }
    raise ArgumentError, "#{self.class}: Directory is empty: #{base_directory}" if entries.empty?
    directory_path = absolute_path(base_directory)

    base_name = File.basename(base_directory)
    file_name = attributes[:id] || base_name
    # Assign a title if source_metadata_identifier is not set
    title = [directory_path.basename]
    attributes[:title] = title if attributes.fetch(:title, []).blank? && attributes.fetch(:source_metadata_identifier, []).blank?
    attributes.merge!(figgy_metadata_file_attributes(base_path: directory_path))
    resource = find_or_create_by(property: property, value: file_name, **attributes)
    child_attributes = attributes.reject { |k, _v| k == :source_metadata_identifier }
    attach_children(path: directory_path, resource: resource, file_filters: file_filters, preserve_file_names: preserve_file_names, **child_attributes)
  end

  def archival_media_bag?(directory)
    Pathname.new(directory).join("bagit.txt").exist?
  end

  private

    def ingest_bag(base_directory:, **attributes)
      IngestArchivalMediaBagJob.perform_later(bag_path: base_directory.to_s, user: nil, **attributes)
    end

    def figgy_metadata_file_attributes(base_path:)
      figgy_metadata_path = base_path.join("figgy_metadata.json")
      return {} unless figgy_metadata_path.exist?
      JSON.parse(figgy_metadata_path.read, symbolize_names: true)
    end

    # Generate an absolute path to a file system node (i. e. directories, files, links, and pipes)
    # @param directory_path [String] the path to the file system node
    # @return [Pathname] the path
    def absolute_path(directory_path)
      path_value = File.absolute_path(directory_path)
      Pathname.new(path_value)
    end

    # When creating children during bulk ingest, if the directory is named
    # "Raster" it should create a Raster Resource. This is to support
    # ScannedMaps with rasters, see [docs/mosaic.md](docs/mosaic.md).
    def child_klass(parent_class:, title:)
      if title.to_s.casecmp("raster").zero?
        RasterResource
      else
        parent_class
      end
    end

    # Determine if the given path looks like a remote identifier, assign it if
    # so - otherwise use it as the title.
    # @note We only check for BibIDs here because there's no way to tell via
    #   regex if a string is title or a component ID, and we don't currently
    #   have a use case for them to be component IDs.
    def title_or_identifier(klass, path_basename)
      if klass.attribute_names.include?(:source_metadata_identifier) && RemoteRecord.catalog?(path_basename.to_s)
        { source_metadata_identifier: path_basename.to_s }
      else
        { title: path_basename }
      end
    end

    # For a given directory and root resource, iterate through the directory file children and ingest them
    # If a subdirectory is found, create a new resource, append this to the parent resource, and recurse through this subdirectory
    # If a file is found, append this to the parent resource
    # @param path [Pathname] the path to the directory containing the child directories
    # @param resource [Resource] the resource being used to construct child resources
    # @param file_filters [Array] the filter used for matching against the filename extension
    def attach_children(path:, resource:, file_filters: [], preserve_file_names: false, **attributes)
      child_attributes = attributes.except(:member_of_collection_ids)
      child_resources = dirs(path: path).map do |subdir_path|
        child_klass = child_klass(parent_class: resource.class, title: subdir_path.basename)
        attach_children(
          path: subdir_path,
          resource: new_resource(klass: child_klass, **child_attributes.merge(title_or_identifier(child_klass, subdir_path.basename))),
          file_filters: file_filters,
          preserve_file_names: preserve_file_names
        )
      end
      child_files = files(path: path, file_filters: file_filters, parent_resource: resource, preserve_file_names: preserve_file_names)

      change_set = ChangeSet.for(resource, change_set_param: change_set_param)
      change_set.validate(member_ids: child_resources.map(&:id), files: child_files)
      change_set_persister.save(change_set: change_set)
    end

    # Accesses the query service for finding repository resources using a metadata property
    # @return [FindByProperty] the query service
    def property_query_service
      @query_service ||= FindByProperty.new(query_service: query_service)
    end

    # Create a new repository resource
    # @param klass [Class] the class of the resource being constructed
    # @return [Resource] the newly created resource
    def new_resource(klass:, **attributes)
      resource = klass.new

      change_set = ChangeSet.for(resource, change_set_param: change_set_param)
      return unless change_set.validate(**attributes)

      persisted = change_set_persister.save(change_set: change_set)
      logger.info "Created the resource #{persisted.id}"
      persisted
    end

    def find_by(property:, value:)
      results = if property.to_sym == :id
                  [query_service.find_by(id: Valkyrie::ID.new(value.to_s))]
                else
                  property_query_service.find_by_property(property: property, value: value).to_a
                end
      raise "Failed to find the resource for #{property}:#{value}" if results.empty?
      results.first
    rescue => error
      logger.warn error.message
      nil
    end

    def find_or_create_by(property:, value:, **attributes)
      resource = find_by(property: property, value: value)
      return resource unless resource.nil?
      new_resource(klass: @klass, **attributes)
    end

    # Retrieve the files within a given directory
    # @param path [Pathname] the path to the directory containing the child directories
    # @return [Array<Pathname>] the paths to any subdirectories
    def dirs(path:)
      path.children.select(&:directory?).sort
    end

    # Retrieve the files within a given directory
    # @param path [Pathname] the path to the directory containing the files
    # @param file_filter [String] the filter used for matching against the filename extension
    # @param parent_resource [Valkyrie::Resource] Parent that the files will be
    #   attached to.
    # @return [Array<Pathname>] the paths to any files
    def files(path:, file_filters: [], preserve_file_names: false, parent_resource:)
      file_paths = path.children.select(&:file?)
      if file_filters.present?
        file_paths = file_paths.select do |file|
          results = file_filters.map { |file_filter| file.extname.ends_with?(file_filter) }
          results.reduce(:|)
        end
      end
      file_paths.reject! { |x| x.basename.to_s.start_with?(".") }
      file_paths.reject! { |x| ignored_file_names.include?(x.basename.to_s) }

      file_paths.sort!
      # Include figgy_metadata if it exists.
      if path.join("figgy_metadata.json").exist?
        file_paths = [path.join("figgy_metadata.json")] + file_paths
      end

      caption_files = Dir[path.join("*.vtt")]
      BulkFilePathConverter.new(file_paths: file_paths, parent_resource: parent_resource, preserve_file_names: preserve_file_names, caption_files: caption_files).to_a
    end

    def ignored_file_names
      ["Thumbs.db", "desktop.ini"]
    end
end
