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
      @copied_file_name ||= BrowseEverything::Retriever.new.download("file_name" => file_name.first, "file_size" => file_size.first, "url" => url.first)
    end
end
