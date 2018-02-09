# frozen_string_literal: true
class FileMetadata < Valkyrie::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
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

  # fixity attributes
  attribute :fixity_actual_checksum, Valkyrie::Types::Set
  attribute :fixity_success, Valkyrie::Types::Int
  attribute :fixity_last_success_date, Valkyrie::Types::DateTime.optional

  def self.for(file:)
    new(label: file.original_filename,
        original_filename: file.original_filename,
        mime_type: file.content_type,
        use: file.try(:use) || [Valkyrie::Vocab::PCDMUse.OriginalFile],
        created_at: Time.current,
        updated_at: Time.current)
  end

  def original_file?
    use.include?(Valkyrie::Vocab::PCDMUse.OriginalFile)
  end

  def derivative?
    use.include?(Valkyrie::Vocab::PCDMUse.ServiceFile)
  end

  # Populates FileMetadata with fixity check results
  # @return [FileMetadata] you'll need to save this node after running the fixity
  def run_fixity
    # don't run if there has been a failure.
    # probably best to create a new FileSet at that point.
    return self if fixity_success&.zero?
    actual_file = Valkyrie.config.storage_adapter.find_by(id: file_identifiers.first)
    new_checksum = MultiChecksum.for(actual_file)
    if checksum.include? new_checksum
      self.fixity_success = 1
      self.fixity_actual_checksum = [new_checksum]
      self.fixity_last_success_date = Time.now.utc
    else
      self.fixity_success = 0
      self.fixity_actual_checksum = [new_checksum]
    end
    self
  end
end
