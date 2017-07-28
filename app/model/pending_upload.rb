# frozen_string_literal: true
class PendingUpload < Valkyrie::Resource
  attribute :id, Valkyrie::Types::ID.optional
  attribute :file_name
  attribute :url
  attribute :file_size, Valkyrie::Types::Set.member(Valkyrie::Types::Coercible::Int)

  def original_filename
    @file_name.first
  end

  def content_type
    'text/plain'
  end

  def path
    copied_file_name
  end

  private

    def copied_file_name
      return @copied_file_name if @copied_file_name
      BrowseEverything::Retriever.new.download("file_name" => file_name.first, "file_size" => file_size.first, "url" => url.first) do |filename, _retrieved, _total|
        @copied_file_name = filename
      end
      @copied_file_name
    end
end
