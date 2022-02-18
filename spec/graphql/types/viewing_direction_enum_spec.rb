# frozen_string_literal: true

require "rails_helper"

RSpec.describe Types::ViewingDirectionEnum do
  subject(:enum) { described_class }
  it "can convert to graphql" do
    expect { enum.to_graphql }.not_to raise_error
  end
end
