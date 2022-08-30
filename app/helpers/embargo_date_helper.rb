# frozen_string_literal: false

module EmbargoDateHelper
  def default_embargo_date(date)
    month, day, year = date.split("/")
    return unless month && day && year
    month = month.to_i - 1
    ":default-date='new Date(#{year}, #{month}, #{day})'"
  rescue StandardError
    nil
  end
end
