# frozen_string_literal: true
module FixityDashboardHelper
  def format_fixity_success_date(date)
    date.nil? ? 'in progress' : date.strftime("%m/%d/%y %I:%M:%S %p %Z")
  end
end
