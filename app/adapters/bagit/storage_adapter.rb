# frozen_string_literal: true
module Bagit
  class StorageAdapter
    attr_reader :base_path
    def initialize(base_path:)
      @base_path = Pathname.new(base_path)
    end

    def for(bag_id:)
      Instance.new(base_path: base_path, bag_id: bag_id.to_s)
    end

    class Instance
      attr_reader :base_path, :bag_id
      def initialize(base_path:, bag_id:)
        @base_path = base_path
        @bag_id = bag_id
      end

      def upload(file:, original_filename:, resource: nil)
        FileUtils.mkdir_p(data_path)
        new_path = data_path.join("#{generate_id}-#{original_filename}")
        old_path = file.try(:disk_path) || file.path
        FileUtils.cp(old_path, new_path)
        output_file = find_by(id: Valkyrie::ID.new("bag://#{new_path.relative_path_from(base_path)}"))
        create_manifests(output_file)
        output_file
      end

      def create_manifests(file)
        checksums = file.checksum(digests: [Digest::SHA1.new, Digest::MD5.new, Digest::SHA256.new])
        file_path = Pathname.new(file_path(file.id)).relative_path_from(bag_path)
        ["sha1", "md5", "sha256"].each_with_index do |algorithm, idx|
          File.open(bag_path.join("manifest-#{algorithm}.txt"), 'a') do |f|
            f.puts("#{checksums[idx]}  #{file_path}")
          end
        end
      end

      def generate_id
        SecureRandom.uuid
      end

      def bag_path
        base_path.join(bag_id)
      end

      def data_path
        bag_path.join("data")
      end

      def find_by(id:)
        Valkyrie::StorageAdapter::File.new(id: Valkyrie::ID.new(id.to_s), io: ::File.open(file_path(id), 'rb'))
      rescue Errno::ENOENT
        raise Valkyrie::StorageAdapter::FileNotFound
      end

      def file_path(id)
        base_path.join(Pathname.new(id.to_s.gsub(/^bag:\/\//, '')))
      end

      def handles?(id:)
        id.to_s.start_with?("bag://")
      end

      def delete(id:)
        path = file_path(id)
        file_path = Pathname.new(file_path(id)).relative_path_from(bag_path)
        FileUtils.rm_rf(path) if File.exist?(path)
        ["sha1", "md5", "sha256"].each do |algorithm|
          lines = File.readlines(bag_path.join("manifest-#{algorithm}.txt")).select do |line|
            !line.include?(file_path.to_s)
          end
          File.open(bag_path.join("manifest-#{algorithm}.txt"), 'w') do |f|
            f.write(lines.join("\n"))
          end
        end
      end
    end
  end
end
