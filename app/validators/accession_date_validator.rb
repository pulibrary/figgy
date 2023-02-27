# frozen_string_literal: true
class AccessionDateValidator < ::ActiveModel::Validator
  def validate(record)
    return if record.date.blank?
    DateTime.strptime(record.date, "%m/%d/%Y")
  rescue Date::Error
    record.errors.add(:date, "Please enter dates as MM/DD/YYYY")
  end
end
