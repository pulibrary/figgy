# frozen_string_literal: true

class SourceMetadataIdentifierValidator < ActiveModel::Validator
  class InvalidMetadataIdentifierError < StandardError; end

  # Validate the structure of a metadata identifier attribute
  # @param record [Valkyrie::Resource]
  # @raise [SourceMetadataIdentifierValidator::InvalidMetadataIdentifierError]
  #   if the metadata identifier has an invalid structure
  def validate(record)
    return unless record.apply_remote_metadata?
    metadata_id = Array(record.source_metadata_identifier).first
    raise URI::InvalidURIError unless RemoteRecord.valid?(metadata_id)
    return if RemoteRecord.retrieve(metadata_id).success?
    record.errors.add(:source_metadata_identifier, "Error retrieving metadata")
  rescue URI::InvalidURIError
    error_message = "Invalid source metadata ID: #{metadata_id}"

    record.errors.add(:source_metadata_identifier, "Value given was not a valid id")
    raise InvalidMetadataIdentifierError, error_message
  end
end
