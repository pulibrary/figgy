# frozen_string_literal: true
module FixityDashboardHelper
  def format_fixity_success_date(date)
    date.nil? ? "in progress" : date.strftime("%m/%d/%y %I:%M:%S %p %Z")
  end

  def format_fixity_success(val)
    case val
    when nil
      "In progress"
    when "n/a"
      "Not tested yet."
    when Event::FAILURE
      "Failed"
    when Event::SUCCESS
      "Successful"
    end
  end

  def format_cloud_fixity_success(val)
    case val
    when nil
      "In progress"
    when "n/a"
      "Not tested yet."
    when Event::FAILURE
      "Failed"
    when Event::SUCCESS
      "Successful"
    end
  end

  def fixity_success_level(val)
    case val
    when nil
      "info"
    when Event::FAILURE
      "warning"
    when Event::SUCCESS
      "primary"
    end
  end
end
