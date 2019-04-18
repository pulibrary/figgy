# frozen_string_literal: true
require "rails_helper"

RSpec.describe UpdateFixityJob do
  describe ".perform" do
    it "updates fixity" do
      described_class.perform_now(status: "SUCCESS", resource_id: "1", child_id: "1")
      # Fill in specs when implementing.
    end
  end
end
