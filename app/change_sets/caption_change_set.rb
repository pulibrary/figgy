# frozen_string_literal: true
class CaptionChangeSet < Valkyrie::ChangeSet
  property :caption_language, multiple: false, type: Valkyrie::Types::String.optional, required: true
  property :change_set, required: true, default: "caption"
  # VTT file uploaded from form.
  property :file, virtual: true, multiple: false, required: true

  validates :file, :caption_language, presence: true

  def primary_terms
    [
      :file,
      :caption_language,
      :change_set
    ]
  end

  def to_ingestable_file
    IngestableFile.new(
      file_path: file.path,
      mime_type: file.content_type,
      original_filename: file.original_filename,
      use: Valkyrie::Vocab::PCDMUse.Caption,
      node_attributes: {
        caption_language: caption_language,
        change_set: change_set
      }
    )
  end
end