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
  def attach_each_dir(base_directory:, property: nil, file_filters: [], **attributes)
    raise ArgumentError, "#{self.class}: Directory does not exist: #{base_directory}" unless File.exist?(base_directory)

    entries = Dir["#{base_directory}/*"]
    raise ArgumentError, "#{self.class}: Directory is empty: #{base_directory}" if entries.empty?
    entries.sort.each do |subdir|
      next unless File.directory?(subdir)
      logger.info "Attaching #{subdir}"
      attach_dir(base_directory: subdir, property: property, file_filters: file_filters, **attributes)
    end
  end

  # Attach files within a directory
  # This may attach to existing resources (such as EphemeraFolder objects) using a property (e. g. "barcode")
  # This may also create new resources (such as ScannedResource objects)
  # @param base_directory [String] the path to the base directory
  # @param property [String, nil] the resource property (when attaching files to existing resources)
  # @param file_filters [Array] the filter used for matching against the filename extension
  def attach_dir(base_directory:, property: nil, file_filters: [], **attributes)
    raise ArgumentError, "#{self.class}: Directory does not exist: #{base_directory}" unless File.exist?(base_directory)

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
    resource = find_or_create_by(property: property, value: file_name, **attributes)
    child_attributes = attributes.reject { |k, _v| k == :source_metadata_identifier }
    attach_children(path: directory_path, resource: resource, file_filters: file_filters, **child_attributes)
  end

  private

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

    # For a given directory and root resource, iterate through the directory file children and ingest them
    # If a subdirectory is found, create a new resource, append this to the parent resource, and recurse through this subdirectory
    # If a file is found, append this to the parent resource
    # @param path [Pathname] the path to the directory containing the child directories
    # @param resource [Resource] the resource being used to construct child resources
    # @param file_filters [Array] the filter used for matching against the filename extension
    def attach_children(path:, resource:, file_filters: [], **attributes)
      child_attributes = attributes.except(:collection)
      child_resources = dirs(path: path).map do |subdir_path|
        attach_children(
          path: subdir_path,
          resource: new_resource(klass: child_klass(parent_class: resource.class, title: subdir_path.basename), **child_attributes.merge(title: [subdir_path.basename])),
          file_filters: file_filters
        )
      end
      child_files = files(path: path, file_filters: file_filters)

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
      collection = attributes.delete(:collection)

      resource = klass.new

      change_set = ChangeSet.for(resource, change_set_param: change_set_param)
      return unless change_set.validate(**attributes)
      change_set.member_of_collection_ids = [collection.id] if collection.try(:id)

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
    # @return [Array<Pathname>] the paths to any files
    def files(path:, file_filters: [])
      file_paths = path.children.select(&:file?)
      if file_filters.present?
        file_paths = file_paths.select do |file|
          results = file_filters.map { |file_filter| file.extname.ends_with?(file_filter) }
          results.reduce(:|)
        end
      end
      file_paths.reject! { |x| x.basename.to_s.start_with?(".") }
      file_paths.reject! { |x| ignored_file_names.include?(x.basename.to_s) }

      BulkFilePathConverter.new(file_paths: file_paths).to_a
    end

    class BulkFilePathConverter
      attr_reader :file_paths
      def initialize(file_paths:)
        @file_paths = file_paths.sort
      end

      def cropped_path_exists?
        @has_cropped ||= file_paths.any? { |f| File.basename(f).include?("_cropped") }
      end

      def to_a
        nodes = []
        file_paths.each_with_index do |f, idx|
          basename = File.basename(f)
          mime_types = MIME::Types.type_for(basename)
          mime_type = mime_types.first
          title = if mime_type && preserved_file_name_mime_types.include?(mime_type.content_type)
                    basename
                  elsif cropped_path_exists?
                    basename
                  else
                    (idx + 1).to_s
                  end
          service_targets = "mosaic" if basename.include?("_cropped")
          nodes << IngestableFile.new(
            file_path: f,
            mime_type: mime_type.content_type,
            original_filename: basename,
            copyable: true,
            container_attributes: {
              title: title,
              service_targets: service_targets
            }
          )
        end
        nodes
      end

      def preserved_file_name_mime_types
        ["audio/x-wav"]
      end
    end

    def ignored_file_names
      ["Thumbs.db"]
    end
end
