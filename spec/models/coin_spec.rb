# frozen_string_literal: true
require "rails_helper"

describe Coin do
  subject(:coin) { described_class.new weight: 5 }

  it "has properties" do
    expect(coin.weight).to eq([5])
  end

  it "has ordered member_ids" do
    coin.member_ids = [1, 2, 3, 3]
    expect(coin.member_ids).to eq [1, 2, 3, 3]
  end
end
