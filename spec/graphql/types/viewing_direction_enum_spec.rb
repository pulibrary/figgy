# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::ViewingDirectionEnum do
  subject(:enum) { described_class }
  it "contains the desired keys" do
    expect(enum.values.keys).to contain_exactly("LEFTTORIGHT", "RIGHTTOLEFT", "TOPTOBOTTOM", "BOTTOMTOTOP")
  end
end
