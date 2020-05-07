# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrowseEverything::Upload do
  describe "#perform_job" do
    it "does nothing" do
      expect(described_class.new.perform_job).to eq nil
    end
  end
end
