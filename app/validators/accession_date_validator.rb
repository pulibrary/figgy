# frozen_string_literal: true
class AccessionDateValidator < ::ActiveModel::Validator
  def validate(record)
    return if record.date.blank?
    return if record.date.is_a?(DateTime)
    record.errors.add(:date, "Please enter dates as MM/DD/YYYY")
  end
end
