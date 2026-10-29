# Checks user submitted paths and makes sure they're not referencing paths
# outside the ingest folder root.
class IngestFolderPath
  class InvalidPath < StandardError; end

  attr_reader :root
  def initialize(root: Figgy.config["ingest_folder_path"])
    @root = Pathname.new(root.to_s)
  end

  def resolve(path)
    real_root = root.realpath
    real_path = root.join(path.to_s.delete_prefix("disk://")).realpath
    unless real_path == real_root || real_path.to_s.start_with?("#{real_root}/")
      raise InvalidPath, "#{path} is outside of #{root}"
    end
    root.join(real_path.relative_path_from(real_root))
  rescue Errno::ENOENT, Errno::ENOTDIR, ArgumentError
    raise InvalidPath, "#{path} does not exist"
  end

  def storage_id(path)
    "disk://#{resolve(path)}"
  end
end
