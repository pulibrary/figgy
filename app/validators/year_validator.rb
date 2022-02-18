# frozen_string_literal: true

class YearValidator < ::ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return if value.delete("-").length <= 4 && value.to_i.to_s == value
    record.errors.add(attribute, "is not a valid year.")
  end
end
