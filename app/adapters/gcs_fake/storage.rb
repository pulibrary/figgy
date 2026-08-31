# A StorageAdapter for use in development and test environments that more
# closely replicates some behaviors of the Google Cloud Storage adapter.
# It uses SimpleDelegators quite heavily because gcs has lots of nested objects.
class GcsFake::Storage < Valkyrie::Storage::Disk
  def find_by(id:)
    output = super
    DecoratedFile.new(output)
  end

  # We need an upload that does streams, since GCS copies streams.
  def upload(file:, original_filename:, resource: nil, **_extra_arguments)
    new_path = path_generator.generate(resource: resource, file: file, original_filename: original_filename)
    FileUtils.mkdir_p(new_path.parent)
    file_mover.call(file, new_path)
    find_by(id: Valkyrie::ID.new("#{protocol}#{new_path}"))
  end

  class DecoratedFile < SimpleDelegator
    def io
      @io ||= DecoratedIo.new(super, self)
    end

    class DecoratedIo < SimpleDelegator
      attr_reader :actual_file
      def initialize(object, actual_file)
        super(object)
        @actual_file = actual_file
      end

      # This mimics a shrine-google_cloud_storage Down:ChunkedIO
      def file
        OpenStruct.new(
          data: {
            file: OpenStruct.new( # mimics Google::Cloud::Storage::File
              md5: compact_md5
            )
          }
        )
      end

      # gcs provides md5s as base65 encoded hex values
      def compact_md5
        Base64.strict_encode64([md5].pack("H*"))
      end

      def md5
        MultiChecksum.for(actual_file).md5
      end
    end
  end
end
