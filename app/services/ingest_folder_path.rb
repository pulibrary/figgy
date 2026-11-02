# Checks user submitted paths and makes sure they're not referencing paths
# outside the ingest folder root.
class IngestFolderPath
  class InvalidPath < StandardError; end

  attr_reader :root
  def initialize(root: Figgy.config["ingest_folder_path"])
    @root = Pathname.new(root.to_s)
  end

  def resolve(path)
    # Ensure that the root ingest path is an absolute path
    expanded_root = File.expand_path(root)

    # Remove leading "disk://" from user supplied path and generate an absolute
    # path relative to the root ingest path
    expanded_path = File.expand_path(path.to_s.delete_prefix("disk://"), expanded_root)

    # Raise en error if the path is outside of the ingest folder
    unless within_root?(expanded_path, expanded_root)
      raise InvalidPath, "#{path} is outside of #{root}"
    end
    raise InvalidPath, "#{path} does not exist" unless File.exist?(expanded_path)
    root.join(Pathname.new(expanded_path).relative_path_from(expanded_root))

  rescue ArgumentError
    # Rescue ArgumentErrors from File.expand_path and re-raise an InvalidPath error
    raise InvalidPath, "#{path} does not exist"
  end

  def storage_id(path)
    "disk://#{resolve(path)}"
  end

  private

    # Determine if a path is inside of the ingest folder or is the ingest folder itself
    def within_root?(expanded_path, expanded_root)
      expanded_path == expanded_root || expanded_path.start_with?("#{expanded_root}/")
    end
end
