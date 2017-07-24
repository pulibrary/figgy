# frozen_string_literal: true
# Generated with `rails generate valkyrie:model ScannedResource`
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe ScannedResource do
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  let(:schema_klass) do
    Class.new(Valkyrie::Resource) do |k|
      k.include PlumSchema
    end
  end
  it "has all the Plum Schema properties" do
    expect(described_class.schema.keys).to include(*schema_klass.schema.keys)
  end
  it "has a viewing_hint" do
    expect(described_class.schema.keys).to include :viewing_hint
  end
  it "has a viewing direction" do
    expect(described_class.schema.keys).to include :viewing_direction
  end
  it "has ordered member_ids" do
    scanned_resource = described_class.new
    scanned_resource.member_ids = [1, 2, 3, 3]
    expect(scanned_resource.member_ids).to eq [1, 2, 3, 3]
  end
end
