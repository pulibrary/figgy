# frozen_string_literal: true

# A StorageAdapter for use in development and test environments that more
# closely replicates some behaviors of the Google Cloud Storage adapter.
# It uses SimpleDelegators quite heavily because gcs has lots of nested objects.
class GcsFake::Storage < Valkyrie::Storage::Disk
  def find_by(id:)
    output = super
    DecoratedFile.new(output)
  end

  class DecoratedFile < SimpleDelegator
    def io
      DecoratedIo.new(super, self)
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
