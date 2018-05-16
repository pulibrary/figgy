# frozen_string_literal: true
require "rails_helper"

RSpec.describe CleanupDerivativesJob do
  describe ".perform" do
    it "clears the queue for dead jobs" do
      expect { described_class.perform_now("bogus") }.not_to raise_error
    end
  end
end
