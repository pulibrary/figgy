# frozen_string_literal: true
# Generated with `rails generate valkyrie:model ScannedResource`
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe ScannedResource do
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
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
  it "generates read groups with the factory" do
    factory = FactoryGirl.build(:complete_private_scanned_resource)
    expect(factory.read_groups).to eq []
  end

  describe "#to_s" do
    it "returns the title if possible" do
      scanned_resource = described_class.new(title: ["One", "Two"])

      expect(scanned_resource.to_s).to eq "Scanned Resource: One and Two"
    end
  end

  describe "structure" do
    let(:structure) do
      {
        "label": "Top!",
        "nodes": [
          {
            "label": "Chapter 1",
            "nodes": [
              {
                "proxy": resource1.id
              }
            ]
          },
          {
            "label": "Chapter 2",
            "nodes": [
              {
                "proxy": resource2.id
              }
            ]
          }
        ]
      }
    end
    let(:resource1) { FactoryGirl.create_for_repository(:file_set) }
    let(:resource2) { FactoryGirl.create_for_repository(:file_set) }
    it "can store structures" do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      scanned_resource = adapter.persister.save(resource: described_class.new(logical_structure: [structure]))

      expect(scanned_resource.logical_structure[0].label).to eq ["Top!"]
      expect(scanned_resource.logical_structure[0].nodes[0].label).to eq ["Chapter 1"]
      expect(scanned_resource.logical_structure[0].nodes[0].nodes[0].proxy).to eq [resource1.id]
      expect(scanned_resource.logical_structure[0].nodes[1].label).to eq ["Chapter 2"]
      expect(scanned_resource.logical_structure[0].nodes[1].nodes[0].proxy).to eq [resource2.id]
    end
  end
end
