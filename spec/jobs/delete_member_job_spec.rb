# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeleteMemberJob do
  describe ".perform" do
    it "does not error when the resource doesn't exist" do
      expect { described_class.perform_now("nonexistent") }.not_to raise_error
    end
  end
end
