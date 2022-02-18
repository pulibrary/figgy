# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe EphemeraBox do
  subject(:box) { described_class.new }
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a constant title" do
    expect(box.title).to include "Ephemera Box"
  end
  it "has ordered member_ids" do
    box.member_ids = [1, 2, 3, 3]
    expect(box.member_ids).to eq [1, 2, 3, 3]
  end
  it "has a downloadable attribute" do
    box.downloadable = ["public"]
    expect(box.downloadable).to eq ["public"]
  end
end
