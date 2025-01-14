# frozen_string_literal: true
class CaptionChangeSet < Valkyrie::ChangeSet
  property :caption_language, multiple: true, type: Valkyrie::Types::Set, required: true
  property :change_set, required: true, default: "caption"
  property :original_language_caption, required: false, type: Dry::Types["params.bool"], default: false
  # VTT file uploaded from form.
  property :file, virtual: true, multiple: false, required: true

  validates :file, :caption_language, presence: true

  def caption_language=(value)
    languages = value.reject(&:empty?).map do |code|
      if ISO_639.find_by_code(code)
        code
      else
        "und"
      end
    end

    @fields["caption_language"] = languages
  end

  def primary_terms
    [
      :file,
      :caption_language,
      :change_set,
      :original_language_caption
    ]
  end

  def to_ingestable_file
    IngestableFile.new(
      file_path: file.path,
      mime_type: file.content_type,
      original_filename: file.original_filename,
      use: ::PcdmUse::Caption,
      node_attributes: fields.except("file").symbolize_keys
    )
  end
end
