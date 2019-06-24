# frozen_string_literal: true
class PendingUpload < Valkyrie::Resource
  attribute :file_name
  attribute :url
  attribute :file_size, Valkyrie::Types::Set.of(Valkyrie::Types::Coercible::Integer)
  attribute :auth_header

  def original_filename
    file_name.first
  end

  def content_type
    "text/plain"
  end

  def path
    copied_file_name
  end

  private

    def headers
      return {} if auth_header.empty?
      JSON.parse auth_header.first
    end

    def copied_file_name
      @copied_file_name ||= BrowseEverything::Retriever.new.download("file_name" => file_name.first, "file_size" => file_size.first, "url" => url.first, "headers" => headers)
    end
end
