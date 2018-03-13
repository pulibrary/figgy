# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FixityDashboardHelper do
  describe '#format_fixity_success_date' do
    it 'formats the date as expected' do
      expect(helper.format_fixity_success_date(nil)).to eq 'in progress'
      time = Time.current
      expect(helper.format_fixity_success_date(time)).to eq time.strftime("%m/%d/%y %I:%M:%S %p %Z")
    end
  end
end
