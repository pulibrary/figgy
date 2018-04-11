# frozen_string_literal: true
class TitleValidator < ActiveModel::Validator
  def validate(record)
    return if Array.wrap(record.title).first.present?
    record.errors.add(:title, "You must provide a source metadata id or a title")
    record.errors.add(:source_metadata_identifier, "You must provide a source metadata id or a title")
  end
end
