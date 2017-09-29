# frozen_string_literal: true
class DateRangeChangeSet < Valhalla::ChangeSet
  validates :start, :end, year: true
  validate :start_before_end
  property :start, multiple: false, required: false
  property :end, multiple: false, required: false

  def start_before_end
    return if start.blank? && self.end.blank?
    return if start.to_i < self.end.to_i
    errors.add(:start, "must be a date before end.")
  end
end
