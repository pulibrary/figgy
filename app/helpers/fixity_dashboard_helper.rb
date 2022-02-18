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
    when "FAILURE"
      "failed"
    when "SUCCESS"
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

  def format_fixity_status(val, count)
    content_tag :div, "#{format_fixity_success(val)} #{format_fixity_count(val, count)}".html_safe
  end

  def format_fixity_count(val, count)
    content_tag :span, count, title: format_fixity_success(val), class: ["fixity-count", "label", "label-#{fixity_success_level(val)}"]
  end
end
