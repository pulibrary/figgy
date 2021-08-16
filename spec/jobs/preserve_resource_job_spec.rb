# frozen_string_literal: true

require "rails_helper"

RSpec.describe PreserveResourceJob do
  it "does not error when given a non-existent ID" do
    expect { described_class.perform_now(id: "none") }.not_to raise_error
  end
end
