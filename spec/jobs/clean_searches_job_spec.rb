# frozen_string_literal: true

require "rails_helper"

RSpec.describe CleanSearchesJob do
  describe ".perform" do
    before do
      allow(Search).to receive(:delete_old_searches)
    end
    it "queries the database for old searches and deletes them" do
      described_class.perform_now
      expect(Search).to have_received(:delete_old_searches).with(7)
    end
  end
end
