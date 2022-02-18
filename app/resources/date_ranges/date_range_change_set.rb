# frozen_string_literal: true

class DateRangeChangeSet < ChangeSet
  validates :start, :end, year: true
  validate :start_before_end
  validate :start_and_end_set
  property :start, multiple: false, required: false
  property :end, multiple: false, required: false
  property :approximate, multiple: false, required: false, type: Valkyrie::Types::Bool

  def start_before_end
    return if start.blank? && self.end.blank?
    return if start.to_i < self.end.to_i
    errors.add(:start, "must be a date before end.")
  end

  def start_and_end_set
    return if start_and_end_set?
    if self.end.present?
      errors.add(:start, "must not be blank if end is set")
    elsif start.present?
      errors.add(:end, "must not be blank if start is set")
    end
  end

  # Returns true if both start and end are either set or not set.
  def start_and_end_set?
    [start, self.end].map(&:present?).uniq.length == 1
  end
end
