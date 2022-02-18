# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe EphemeraProject do
  subject(:project) { described_class.new(title: "test name") }
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a title" do
    expect(project.title).to include "test name"
  end
  it "has ordered member_ids" do
    project.member_ids = [1, 2, 3, 3]
    expect(project.member_ids).to eq [1, 2, 3, 3]
  end
  it "has property top_language" do
    expect(project.top_language).to eq []
  end
  it "has a list of contributor_uids" do
    project.contributor_uids = ["tpend"]
    expect(project.contributor_uids).to eq ["tpend"]
  end
end
