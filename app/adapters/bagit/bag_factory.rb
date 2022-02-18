# frozen_string_literal: true

module Bagit
  class BagFactory
    attr_reader :adapter
    delegate :base_path, to: :adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    def new(resource:)
      Bagit::BagFactory::ResourceFactory.new(adapter: adapter, resource: resource)
    end

    class ResourceFactory
      attr_reader :adapter, :resource
      delegate :base_path, to: :adapter
      def initialize(adapter:, resource:)
        @adapter = adapter
        @resource = resource
      end

      def create!
        FileUtils.mkdir_p(bag_path)
        unless adapter.nested?
          create_bagit_txt
          create_bag_info
        end
        export_metadata
      end

      def delete!
        if adapter.nested?
          lines = File.readlines(bag_path.join("tagmanifest-sha256.txt")).select do |line|
            !line.include?(metadata_digest_path.relative_path_from(bag_path).to_s)
          end
          File.write(bag_path.join("tagmanifest-sha256.txt"), lines.join("\n"))
          FileUtils.rm_f(metadata_digest_path)
        else
          FileUtils.rm_rf(bag_path)
        end
      end

      private

        def bag_path
          @bag_path ||= adapter.bag_path(id: resource.id)
        end

        def create_bagit_txt
          render_template_to_file(template: "bagit.txt.erb", file: bag_path.join("bagit.txt"))
        end

        def create_bag_info
          render_template_to_file(template: "bag-info.txt.erb", file: bag_path.join("bag-info.txt"))
        end

        def export_metadata
          FileUtils.mkdir_p(bag_path.join("metadata"))
          File.write(metadata_digest_path, resource_metadata.to_json)
          digest_metadata
        end

        def metadata_digest_path
          bag_path.join("metadata", "#{resource.id}.jsonld")
        end

        def digest_metadata
          hash = Digest::SHA256.file(metadata_digest_path).hexdigest
          File.open(bag_path.join("tagmanifest-sha256.txt"), "a") do |f|
            f.puts("#{hash}  #{metadata_digest_path.relative_path_from(bag_path)}")
          end
        end

        def resource_metadata
          output = resource.to_h.except(:imported_metadata).compact
          if output[:optimistic_lock_token]
            output[:optimistic_lock_token] = Array.wrap(output[:optimistic_lock_token]).map(&:serialize)
          end
          output
        end

        def render_template_to_file(template:, file:)
          output = ERB.new(File.read(template_path.join(template)), nil, "-").result(binding)
          File.write(file, output)
        end

        def template_path
          Pathname.new(__dir__).join("templates")
        end

        def helper
          @helper ||= ManifestBuilder::ManifestHelper.new
        end
    end
  end
end
