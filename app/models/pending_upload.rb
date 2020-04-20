# frozen_string_literal: true
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

  def original_filename
    file_name.first
  end

  def content_type
    "text/plain"
  end

  def path
    copied_file_name
  end

  def container?
    type.present? && type.first == browse_everything_provider.class.container_mime_type
  end

  private

    def headers
      return {} if auth_header.blank?
      JSON.parse auth_header.first
    end

    def copied_file_name
      @copied_file_name ||= BrowseEverything::Retriever.new.download(
        "file_name" => file_name.first,
        "file_size" => file_size.first,
        "url" => url.first,
        "headers" => headers,
        "type" => type,
        "provider" => provider
      )
    end

    def browse_everything_provider
      return if provider.empty?

      @browse_everything_provider ||= BrowserFactory.for(name: provider.first)
    end
end
