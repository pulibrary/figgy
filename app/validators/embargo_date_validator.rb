# frozen_string_literal: true
class EmbargoDateValidator < ActiveModel::Validator
  def validate(record)
    value = record.embargo_date
    return if value.blank?
    return if /\b([1-9]|[1][0-2])\/([1-2][0-9]?|[3][0-1]|[1-9])\/[0-9]{4}/.match?(value)
    record.errors.add(:embargo_date, "Date must have form 'mm/dd/YYYY' with no leading zeros")
  end
end
