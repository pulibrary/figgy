# frozen_string_literal: true
class FileSet < Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :title, Valkyrie::Types::Set
  attribute :file_metadata, Valkyrie::Types::Set.of(FileMetadata.optional)
  attribute :viewing_hint
  attribute :depositor
  attribute :local_identifier
  attribute :hocr_content
  attribute :ocr_content
  attribute :barcode, Valkyrie::Types::Set
  attribute :part, Valkyrie::Types::Set
  attribute :transfer_notes

  delegate :width,
           :height,
           :x_resolution,
           :y_resolution,
           :bits_per_sample,
           :size,
           :camera_model,
           :software,
           :geometry,
           :run_fixity,
           :processing_note,
           :error_message,
           to: :original_file,
           allow_nil: true

  delegate :date_of_digitization, :producer, :source_media_type, :duration, to: :preservation_file, allow_nil: true

  delegate :md5, :sha1, :sha256, to: :original_file_checksum, allow_nil: true

  def thumbnail_id
    id
  end

  def derivative_file
    file_metadata.find(&:derivative?)
  end

  def derivative_files
    file_metadata.select(&:derivative?)
  end

  def original_file
    file_metadata.find(&:original_file?)
  end

  def original_files
    file_metadata.select(&:original_file?)
  end

  def thumbnail_files
    file_metadata.select(&:thumbnail_file?)
  end

  def preservation_file
    file_metadata.find(&:preservation_file?)
  end

  def preservation_files
    file_metadata.select(&:preservation_file?)
  end

  def intermediate_files
    file_metadata.select(&:intermediate_file?)
  end

  def mime_type
    if original_file
      original_file.mime_type
    elsif preservation_file
      preservation_file.mime_type
    end
  end

  def audio?
    Array.wrap(mime_type).first.to_s.include?("audio/")
  end

  private

    def original_file_checksum
      original_file&.checksum&.first
    end
end
