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

  delegate :path, :original_filename, to: :ingestable_file

  # This is normally overridden during characterization
  def content_type
    "application/octet-stream"
  end

  def close
    # Clean up file handles.
    storage_adapter_file.close
    ingestable_file.close
  end

  private

    def ingestable_file
      return unless storage_adapter_id
      @ingestable_file ||=
        IngestableFile.new(
            file_path: storage_adapter_file.disk_path,
            mime_type: content_type,
            original_filename: storage_adapter_file.disk_path.basename.to_s,
            # PendingUploads are used via ServerUploadJob, so disk_via_copy
            # adapter is used.
            copy_before_ingest: true
          )
    end

    def storage_adapter_file
      return unless storage_adapter_id
      @storage_adapter_file ||= Valkyrie::StorageAdapter.find_by(id: storage_adapter_id)
    end
end
