# frozen_string_literal: true
module FixityDashboardHelper
  def format_fixity_success_date(date)
    date.nil? ? "in progress" : date.strftime("%m/%d/%y %I:%M:%S %p %Z")
  end

  def format_fixity_success(val)
    case val
    when nil
      "in progress"
    when 0
      "failed"
    when 1
      "succeeded"
    end
  end

  def format_cloud_fixity_success(val)
    case val
    when nil
      "in progress"
    when Event::FAILURE
      "failed"
    when Event::SUCCESS
      "succeeded"
    end
  end

  def fixity_success_level(val)
    case val
    when nil
      "info"
    when 0
      "warning"
    when 1
      "primary"
    end
  end
end
