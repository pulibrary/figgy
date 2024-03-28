# frozen_string_literal: true
require "rails_helper"

RSpec.describe ApplicationCable::Connection do
  it "is referencable" do
    expect { described_class }.not_to raise_error
  end
end
