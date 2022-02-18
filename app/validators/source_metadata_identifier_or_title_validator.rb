# frozen_string_literal: true

class SourceMetadataIdentifierOrTitleValidator < ActiveModel::Validator
  def validate(record)
    return if record.source_metadata_identifier.present? || Array.wrap(record.title).first.present?
    record.errors.add(:title, "You must provide a source metadata id or a title")
    record.errors.add(:source_metadata_identifier, "You must provide a source metadata id or a title")
  end
end
