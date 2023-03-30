# frozen_string_literal: true
require "tempfile"

class PendingUpload < Valkyrie::Resource
  attribute :storage_adapter_id, Valkyrie::Types::ID.optional
  attribute :file_name
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
  attribute :upload_id
  attribute :upload_file_id

  # This is still needed
  def original_filename
    if ingestable_file
      ingestable_file.original_filename
    else
      upload_file.name
    end
  end

  def path
    if ingestable_file
      ingestable_file.path
    else
      downloaded_file
    end
  end

  # This is normally overridden during characterization
  def content_type
    "application/octet-stream"
  end

  delegate :container_id, to: :upload_file

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

    def upload_file
      @upload_file ||= begin
                         upload_files = BrowseEverything::UploadFile.find(upload_file_id)
                         upload_files.first
                       end
    end
    delegate :bytestream, to: :upload_file

    def downloaded_file
      @downloaded_file ||=
        begin
          target = Dir::Tmpname.create(original_filename) {}
          File.open(target, "wb") do |output|
            output.write(upload_file.download)
          end
          upload_file.purge_bytestream
          target
        end
    end
end
