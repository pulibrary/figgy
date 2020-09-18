# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchHistoryController do
  routes { Blacklight::Engine.routes }
  # We don't add any functionality here, but the override is necessary for
  # Blacklight::RangeLimit, so to get coverage up we have this test.
  it "is accessible" do
    expect { get :index }.not_to raise_error
  end
end
