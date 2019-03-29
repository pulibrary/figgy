# frozen_string_literal: true
class FileSetChangeSet < ChangeSet
  self.fields = [:title]
  property :files, virtual: true, multiple: true, required: false
  property :viewing_hint, multiple: false, required: false
  property :hocr_content, multiple: false, required: false
  property :ocr_content, multiple: false, required: false
  property :read_groups, multiple: true, required: false
  property :remote_checksum, multiple: false, required: false
  property :file_metadata, multiple: true, required: false, type: Types::Strict::Array.of(FileMetadata)
  delegate :thumbnail_id, to: :model

  def primary_terms
    [:title]
  end
end
