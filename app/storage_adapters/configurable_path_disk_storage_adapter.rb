# frozen_string_literal: true
class ConfigurablePathDiskStorageAdapter
  attr_reader :base_path, :path_generator, :unique_identifier
  def initialize(base_path:, unique_identifier:, path_generator: BucketedStorage)
    @base_path = base_path
    @unique_identifier = unique_identifier
    @path_generator = path_generator.new(base_path: base_path)
  end

  def upload(file:, resource: nil)
    new_path = path_generator.generate(resource: resource, file: file)
    return find_by(id: Valkyrie::ID.new("configurable_path_#{unique_identifier}://#{new_path.id}")) if new_path.exist?
    FileUtils.mkdir_p(new_path.parent)
    FileUtils.mv(file.path, new_path, force: true)
    find_by(id: Valkyrie::ID.new("configurable_path_#{unique_identifier}://#{new_path.id}"))
  end

  def find_by(id:)
    return unless handles?(id: id)
    ::Valkyrie::StorageAdapter::File.new(id: Valkyrie::ID.new(id.to_s), io: path_generator.file(clean_id(id)))
  end

  def clean_id(id)
    id.to_s.gsub("configurable_path_#{unique_identifier}://", "")
  end

  def handles?(id:)
    id.to_s.start_with?("configurable_path_#{unique_identifier}://")
  end

  class BucketedStorage
    attr_reader :base_path
    def initialize(base_path:)
      @base_path = base_path
    end

    def generate(file:, resource:)
      Path.new(Pathname.new(base_path).join(*bucketed_path(resource.id)).join(file.original_filename))
    end

    def bucketed_path(id)
      cleaned_id = id.to_s.delete("-")
      cleaned_id[0..5].chars.each_slice(2).map(&:join) + [cleaned_id]
    end

    def file(id)
      File.open(id.to_s, 'rb')
    end

    class Path
      attr_reader :path
      def initialize(path)
        @path = path
      end

      def id
        path.to_s
      end

      delegate :parent, to: :path

      def to_str
        path.to_s
      end

      def exist?
        false
      end
    end
  end

  class ContentAddressablePath
    attr_reader :base_path
    def initialize(base_path:)
      @base_path = base_path
    end

    def generate(file:, resource: nil)
      sha = sha(file).to_s
      Path.new(sha: sha, path: path_from_sha(sha).join("#{sha}#{file.original_filename.gsub(/^.*\./, '.')}"))
    end

    def sha(file)
      Digest::SHA256.file(file.path)
    end

    def bucketed_path(sha)
      sha[0..11].chars.each_slice(4).map(&:join)
    end

    def path_from_sha(sha)
      Pathname.new(base_path).join(*bucketed_path(sha))
    end

    def file(id)
      sha, extension = id.split(".")
      File.open(path_from_sha(sha).join("#{sha}.#{extension}"), 'rb')
    end

    class Path
      attr_reader :sha, :path
      def initialize(sha:, path:)
        @sha = sha
        @path = path
      end

      delegate :exist?, to: :path

      delegate :parent, to: :path

      def to_str
        path.to_s
      end

      def id
        "#{sha}#{path.extname}"
      end
    end
  end
end
