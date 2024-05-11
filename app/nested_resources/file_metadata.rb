# frozen_string_literal: true
class FileMetadata < Valkyrie::Resource
  def self.supports_save_and_duplicate?
    false
  end

  include Valkyrie::Resource::AccessControls
  attribute :label, Valkyrie::Types::Set
  attribute :mime_type, Valkyrie::Types::Set
  attribute :height, Valkyrie::Types::Set
  attribute :width, Valkyrie::Types::Set
  attribute :bits_per_sample, Valkyrie::Types::Set
  attribute :x_resolution, Valkyrie::Types::Set
  attribute :y_resolution, Valkyrie::Types::Set
  attribute :camera_model, Valkyrie::Types::Set
  attribute :software, Valkyrie::Types::Set
  attribute :checksum, Valkyrie::Types::Set
  attribute :original_filename, Valkyrie::Types::Set
  attribute :file_identifiers, Valkyrie::Types::Set
  attribute :use, Valkyrie::Types::Set
  attribute :size, Valkyrie::Types::Set
  attribute :geometry, Valkyrie::Types::Set
  attribute :bounds, Valkyrie::Types::Set
  attribute :processing_note, Valkyrie::Types::Set
  attribute :error_message, Valkyrie::Types::Set

  attribute :date_of_digitization, Valkyrie::Types::Set # Encoded_date
  attribute :producer, Valkyrie::Types::Set # Producer
  attribute :source_media_type, Valkyrie::Types::Set # OriginalSourceForm
  attribute :duration, Valkyrie::Types::Set # Duration in seconds

  # PDF Metadata
  attribute :page_count, Valkyrie::Types::Integer

  # Caption Metadata
  attribute :caption_language, Valkyrie::Types::String.optional
  attribute :original_language_caption, Valkyrie::Types::Bool.optional
  attribute :change_set, Valkyrie::Types::String

  # preservation attributes
  # ID of the object this node is a preservation copy of. A PreservationObject's
  # binary_node (which is a FileMetadata object) uses this value to point to a
  # FileSet's FileMetadata ID. This value is used for checking if something is
  # already preserved.
  attribute :preservation_copy_of_id, Valkyrie::Types::ID.optional

  def self.for(file:)
    new(label: file.original_filename,
        original_filename: file.original_filename,
        mime_type: file.content_type,
        use: file.try(:use) || [::PcdmUse::OriginalFile],
        created_at: Time.current,
        updated_at: Time.current,
        id: SecureRandom.uuid)
  end

  def derivative?
    use.include?(::PcdmUse::ServiceFile)
  end

  # ServiceFilePartial isn't part of the PCDMUse vocabulary - this is made up
  def derivative_partial?
    use.include?(::PcdmUse::ServiceFilePartial)
  end

  def original_file?
    use.include?(::PcdmUse::OriginalFile)
  end

  def thumbnail_file?
    use.include?(::PcdmUse::ThumbnailImage)
  end

  def preservation_file?
    use.include?(::PcdmUse::PreservationFile) ||
      use.include?(::PcdmUse::PreservationMasterFile)
  end

  def preserved_metadata?
    use.include?(::PcdmUse::PreservedMetadata)
  end

  def preservation_copy?
    use.include?(::PcdmUse::PreservationCopy)
  end

  def intermediate_file?
    use.include?(::PcdmUse::IntermediateFile)
  end

  def cloud_derivative?
    use.include?(::PcdmUse::CloudDerivative)
  end

  def caption?
    use.include?(::PcdmUse::Caption)
  end

  def image?
    mime_type.first.include?("image")
  end

  def pdf?
    mime_type.first == "application/pdf"
  end

  def av?
    audio? || video?
  end

  def hls_manifest?
    mime_type.first.include?("application/x-mpegURL")
  end

  def av_derivative?
    (derivative? || derivative_partial?) && (av? || hls_manifest?)
  end

  def audio?
    mime_type&.first&.include?("audio")
  end

  def video?
    mime_type&.first&.include?("video")
  end

  def preserve?
    original_file? || intermediate_file? || preservation_copy? || preservation_file?
  end

  def cloud_uri
    return unless cloud_derivative?
    file_id = file_identifiers.first.to_s
    if file_id.include?("shrine")
      file_id.gsub("cloud-geo-derivatives-shrine://", "s3://#{Figgy.config['cloud_geo_bucket']}/")
    else
      file_id.gsub("disk:/", "")
    end
  end

  def caption_language_label
    label = ControlledVocabulary.for(:language).label(caption_language)
    return label unless original_language_caption
    "#{label} (Original)"
  end
end
