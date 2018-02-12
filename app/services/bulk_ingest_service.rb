# frozen_string_literal: true
class BulkIngestService
  attr_reader :change_set_persister, :logger
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter
  def initialize(change_set_persister:, klass: ScannedResource, logger: Valkyrie.logger)
    @change_set_persister = change_set_persister
    @klass = klass
    @logger = logger
  end

  def attach_each_dir(base_directory:, property: nil, file_filter: nil, **attributes)
    Dir["#{base_directory}/*"].sort.each do |subdir|
      next unless File.directory?(subdir)
      logger.info "Attaching #{subdir}"
      attach_dir(base_directory: subdir, property: property, file_filter: file_filter, **attributes)
    end
  end

  # Attach files within a directory
  # This may attach to existing resources (such as EphemeraFolder objects) using a property (e. g. "barcode")
  # This may also create new resources (such as ScannedResource objects)
  # @param base_directory [String] the path to the base directory
  # @param property [String] the resource property (for an existing resource)
  # @param file_filter [String] the filter used for matching against the filename extension
  def attach_dir(base_directory:, property: nil, file_filter: nil, **attributes)
    directory_path = Pathname.new(base_directory)
    file_name = attributes[:id] || File.basename(base_directory)
    attributes[:title] = [directory_path.basename] if attributes.fetch(:title, []).blank?

    resource = find_or_create_by(property: property, value: file_name, **attributes)
    child_attributes = attributes.reject { |k, _v| k == :source_metadata_identifier }
    attach_children(path: directory_path, resource: resource, file_filter: file_filter, **child_attributes)
  end

  # For a given directory and root resource, iterate through the directory file children and ingest them
  # If a subdirectory is found, create a new resource, append this to the parent resource, and recurse through this subdirectory
  # If a file is found, append this to the parent resource
  def attach_children(path:, resource:, file_filter: nil, **attributes)
    child_attributes = attributes.except(:collection)

    child_resources = dirs(path: path).map do |subdir_path|
      attach_children(
        path: subdir_path,
        resource: new_resource(klass: resource.class, **child_attributes.merge(title: [subdir_path.basename])),
        file_filter: file_filter
      )
    end
    child_files = files(path: path, file_filter: file_filter)

    change_set = DynamicChangeSet.new(resource)
    change_set.validate(member_ids: child_resources.map(&:id), files: child_files)
    change_set.sync
    change_set_persister.save(change_set: change_set)
  end

  private

    def property_query_service
      @query_service ||= FindByStringProperty.new(query_service: query_service)
    end

    def new_resource(klass:, **attributes)
      collection = attributes.delete(:collection)

      resource = klass.new

      change_set = DynamicChangeSet.new(resource)
      change_set.prepopulate!
      return unless change_set.validate(**attributes)
      change_set.member_of_collection_ids = [collection.id] if collection.try(:id)

      change_set.sync
      persisted = change_set_persister.save(change_set: change_set)
      logger.info "Created the resource #{persisted.id}"
      persisted
    end

    def find_by(property:, value:)
      results = if property.to_sym == :id
                  [query_service.find_by(id: Valkyrie::ID.new(value.to_s))]
                else
                  property_query_service.find_by_string_property(property: property, value: value).to_a
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
    # @param path [Pathname] the path to the directory containing the sbudirectories
    # @param file_filter [String] the filter used for matching against the filename extension
    # @return [Array<Pathname>] the paths to any subdirectories
    def dirs(path:)
      path.children.select(&:directory?).sort
    end

    # Retrieve the files within a given directory
    # @param path [Pathname] the path to the directory containing the files
    # @param file_filter [String] the filter used for matching against the filename extension
    # @return [Array<Pathname>] the paths to any files
    def files(path:, file_filter: nil)
      file_paths = path.children.select(&:file?)
      file_paths = file_paths.select { |file| file.extname.ends_with?(file_filter) } if file_filter.present?
      file_paths.reject! { |x| x.basename.to_s.start_with?(".") }

      nodes = []
      file_paths.sort.each_with_index do |f, idx|
        nodes << IngestableFile.new(
          file_path: f,
          mime_type: "image/tiff",
          original_filename: File.basename(f),
          copyable: true,
          container_attributes: {
            title: (idx + 1).to_s
          }
        )
      end
      nodes
    end
end
