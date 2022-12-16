# frozen_string_literal: true
require "tempfile"

class PendingUpload < Valkyrie::Resource
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
    upload_file.name
  end

  def path
    downloaded_file
  end

  # This is normally overridden during characterization
  def content_type
    "application/octet-stream"
  end

  delegate :container_id, to: :upload_file

  private

    def upload_file
      @upload_file ||= begin
                         upload_files = BrowseEverything::UploadFile.find(upload_file_id)
                         upload_files.first
                       end
    end
    delegate :bytestream, to: :upload_file

    def downloaded_file
      @downloaded_file ||= begin
                             target = Dir::Tmpname.create(original_filename) {}
                             File.open(target, "wb") do |output|
                               output.write(upload_file.download)
                             end
                             upload_file.purge_bytestream
                             target
                           end
    end
end
