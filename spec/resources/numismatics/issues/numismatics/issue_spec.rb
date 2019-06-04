# frozen_string_literal: true
require "rails_helper"

describe Numismatics::Issue do
  subject(:issue) { described_class.new metal: "bronze" }

  it "has properties" do
    expect(issue.metal).to eq(["bronze"])
  end

  it "has ordered member_ids" do
    issue.member_ids = [1, 2, 3, 3]
    expect(issue.member_ids).to eq [1, 2, 3, 3]
  end

  it "has a title" do
    expect(issue.title).to include "Issue: "
  end

  it "has a downloadable attribute" do
    issue.downloadable = ["public"]
    expect(issue.downloadable).to eq ["public"]
  end
end
