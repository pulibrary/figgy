# frozen_string_literal: true
require "tempfile"

class PendingUpload < Valkyrie::Resource
  attribute :storage_adapter_id, Valkyrie::Types::ID.optional
  attribute :file_name, Valkyrie::Types::String
  attribute :local_id
  attribute :url
  attribute :file_size, Valkyrie::Types::Set.of(Valkyrie::Types::Coercible::Integer)
  attribute :auth_token
  attribute :auth_header
  attribute :type
  attribute :provider
  # Store optional extra upload arguments which can be passed to StorageAdapter#upload.
  # Currently used for passing height/width to S3.
  attribute :upload_arguments, Valkyrie::Types::Hash

  # This is still needed
  delegate :original_filename, to: :ingestable_file

  delegate :path, to: :ingestable_file

  # This is normally overridden during characterization
  def content_type
    "application/octet-stream"
  end

  private

    def ingestable_file
      return unless storage_adapter_id
      @ingestable_file ||=
        begin
          IngestableFile.new(
            file_path: storage_adapter_file.disk_path,
            mime_type: content_type,
            original_filename: storage_adapter_file.disk_path.basename.to_s,
            copy_before_ingest: false
          )
        end
    end

    def storage_adapter_file
      return unless storage_adapter_id
      @storage_adapter_file ||= Valkyrie::StorageAdapter.find_by(id: storage_adapter_id)
    end
end
