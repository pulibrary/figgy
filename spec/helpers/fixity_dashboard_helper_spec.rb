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

  describe '#format_fixity_success' do
    it 'translates the nil / 0 / 1 into human-readable text' do
      expect(helper.format_fixity_success(nil)).to eq 'in progress'
      expect(helper.format_fixity_success(0)).to eq 'failed'
      expect(helper.format_fixity_success(1)).to eq 'succeeded'
    end
  end
end
