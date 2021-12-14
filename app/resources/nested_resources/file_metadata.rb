# frozen_string_literal: true
class FileMetadata < Valkyrie::Resource
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
  attribute :processing_note, Valkyrie::Types::Set
  attribute :error_message, Valkyrie::Types::Set

  attribute :date_of_digitization, Valkyrie::Types::Set # Encoded_date
  attribute :producer, Valkyrie::Types::Set # Producer
  attribute :source_media_type, Valkyrie::Types::Set # OriginalSourceForm
  attribute :duration, Valkyrie::Types::Set # Duration

  # fixity attributes
  attribute :fixity_actual_checksum, Valkyrie::Types::Set
  attribute :fixity_success, Valkyrie::Types::Integer
  attribute :fixity_last_success_date, Valkyrie::Types::DateTime.optional

  # PDF Metadata
  attribute :page_count, Valkyrie::Types::Integer

  # preservation attributes
  # ID of the object this node is a preservation copy of. Points to another
  # FileMetadata ID (in a PreservationObject), and used for checking if something is
  # already preserved.
  attribute :preservation_copy_of_id, Valkyrie::Types::ID.optional

  def self.for(file:)
    new(label: file.original_filename,
        original_filename: file.original_filename,
        mime_type: file.content_type,
        use: file.try(:use) || [Valkyrie::Vocab::PCDMUse.OriginalFile],
        created_at: Time.current,
        updated_at: Time.current,
        id: SecureRandom.uuid)
  end

  def derivative?
    use.include?(Valkyrie::Vocab::PCDMUse.ServiceFile)
  end

  # ServiceFilePartial isn't part of the PCDMUse vocabulary - this is made up
  def derivative_partial?
    use.include?(Valkyrie::Vocab::PCDMUse.ServiceFilePartial)
  end

  def original_file?
    use.include?(Valkyrie::Vocab::PCDMUse.OriginalFile)
  end

  def thumbnail_file?
    use.include?(Valkyrie::Vocab::PCDMUse.ThumbnailImage)
  end

  def preservation_file?
    use.include?(Valkyrie::Vocab::PCDMUse.PreservationMasterFile)
  end

  def preserved_metadata?
    use.include?(Valkyrie::Vocab::PCDMUse.PreservedMetadata)
  end

  def preservation_copy?
    use.include?(Valkyrie::Vocab::PCDMUse.PreservationCopy)
  end

  def intermediate_file?
    use.include?(Valkyrie::Vocab::PCDMUse.IntermediateFile)
  end

  def cloud_derivative?
    use.include?(Valkyrie::Vocab::PCDMUse.CloudDerivative)
  end

  def image?
    mime_type.first.include?("image")
  end

  def pdf?
    mime_type.first == "application/pdf"
  end

  # Populates FileMetadata with fixity check results
  # @return [FileMetadata] you'll need to save this node after running the fixity
  def run_fixity
    # don't run if there has been a failure.
    # probably best to create a new FileSet at that point.
    # also don't run if there's no existing checksum; characterization hasn't finished
    return self if fixity_success&.zero? || checksum.empty?
    actual_file = Valkyrie::StorageAdapter.find_by(id: file_identifiers.first)
    new_checksum = MultiChecksum.for(actual_file)
    if checksum.include? new_checksum
      self.fixity_success = 1
      self.fixity_actual_checksum = [new_checksum]
      self.fixity_last_success_date = Time.now.utc
    else
      self.fixity_success = 0
      self.fixity_actual_checksum = [new_checksum]
      Honeybadger.notify("Local fixity failure on file #{actual_file.id}")
    end
    self
  end
end
