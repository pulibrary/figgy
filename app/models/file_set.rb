# frozen_string_literal: true
class FileSet < Resource
  include Valkyrie::Resource::AccessControls
  attribute :title, Valkyrie::Types::Set
  attribute :file_metadata, Valkyrie::Types::Set.of(FileMetadata.optional)
  attribute :viewing_hint
  attribute :depositor
  attribute :local_identifier
  attribute :hocr_content
  attribute :ocr_content
  attribute :barcode, Valkyrie::Types::Set
  attribute :side, Valkyrie::Types::Set
  attribute :part, Valkyrie::Types::Set
  attribute :transfer_notes
  attribute :processing_status, Valkyrie::Types::String.optional
  attribute :cached_parent_id, Valkyrie::Types::ID.optional
  attribute :service_targets, Valkyrie::Types::Set

  delegate :width,
           :height,
           :x_resolution,
           :y_resolution,
           :bits_per_sample,
           :size,
           :camera_model,
           :software,
           :geometry,
           :bounds,
           :processing_note,
           :error_message,
           :mime_type,
           :av?,
           :video?,
           :audio?,
           to: :primary_file,
           allow_nil: true

  delegate :date_of_digitization, :producer, :source_media_type, :duration, to: :preservation_file, allow_nil: true

  delegate :md5, :sha1, :sha256, to: :primary_file_checksum, allow_nil: true

  def thumbnail_id
    id
  end

  def derivative_file
    derivative_files.last
  end

  def derivative_files
    file_metadata.select(&:derivative?)
  end

  def cloud_derivative_files
    file_metadata.select(&:cloud_derivative?)
  end

  def pyramidal_derivative
    derivative_files.find do |derivative|
      derivative.mime_type.include?("image/tiff")
    end
  end

  def derivative_partial_files
    file_metadata.select(&:derivative_partial?)
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

  def intermediate_file
    file_metadata.find(&:intermediate_file?)
  end

  def intermediate_files
    file_metadata.select(&:intermediate_file?)
  end

  def captions
    file_metadata.select(&:caption?)
  end

  def primary_file
    if original_file
      original_file
    elsif preservation_file
      preservation_file
    elsif intermediate_file
      intermediate_file
    end
  end

  def fixity_checked_file_ids
    [original_file&.id, preservation_file&.id, intermediate_file&.id].compact
  end

  def image?
    Array.wrap(mime_type).first.to_s.include?("image/")
  end

  def captions?
    av? && captions.present?
  end

  # True if it's a video fileset and has no original language caption.
  def missing_captions?
    return false unless video?
    captions.select(&:original_language_caption).blank?
  end

  def preservation_targets
    original_files + intermediate_files + preservation_files
  end

  private

    def primary_file_checksum
      primary_file&.checksum&.first
    end
end
