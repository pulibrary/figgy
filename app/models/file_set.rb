# frozen_string_literal: true
class FileSet < Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :title, Valkyrie::Types::Set
  attribute :file_metadata, Valkyrie::Types::Set.member(FileMetadata.optional)
  attribute :viewing_hint
  attribute :depositor
  attribute :local_identifier
  attribute :hocr_content
  attribute :ocr_content
  attribute :barcode
  attribute :part

  delegate :width, :height, :x_resolution, :y_resolution, :bits_per_sample, :mime_type, :size, :camera_model, :software, :geometry, :run_fixity, :processing_note, to: :original_file, allow_nil: true
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

  def preservation_files
    file_metadata.select(&:preservation_file?)
  end

  def intermediate_files
    file_metadata.select(&:intermediate_file?)
  end

  private

    def original_file_checksum
      original_file&.checksum&.first
    end
end
