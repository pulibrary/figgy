# frozen_string_literal: true
class AccessionDateValidator < ::ActiveModel::Validator
  def validate(record)
    return if record.date.blank?
    DateTime.strptime(record.date, "%Y-%m-%d")
  rescue Date::Error
    record.errors.add(:date, "Please enter dates as YYYY-MM-DD")
  end
end
