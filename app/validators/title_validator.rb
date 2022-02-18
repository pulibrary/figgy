# frozen_string_literal: true

class TitleValidator < ActiveModel::Validator
  def validate(record)
    return if Array.wrap(record.title).first.present?
    record.errors.add(:title, "You must provide a title")
  end
end
