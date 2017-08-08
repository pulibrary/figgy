# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe MultiVolumeWork do
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a viewing_hint" do
    expect(described_class.schema.keys).to include :viewing_hint
  end
  it "has a viewing direction" do
    expect(described_class.schema.keys).to include :viewing_direction
  end
  it "has ordered member_ids" do
    multi_volume_work = described_class.new
    multi_volume_work.member_ids = [1, 2, 3, 3]
    expect(multi_volume_work.member_ids).to eq [1, 2, 3, 3]
  end
  it "generates read groups with the factory" do
    factory = FactoryGirl.build(:complete_private_multi_volume_work)
    expect(factory.read_groups).to eq []
  end

  describe "#to_s" do
    it "returns the title if possible" do
      multi_volume_work = described_class.new(title: ["One", "Two"])

      expect(multi_volume_work.to_s).to eq "Multi Volume Work: One and Two"
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
      multi_volume_work = adapter.persister.save(resource: described_class.new(logical_structure: [structure]))

      expect(multi_volume_work.logical_structure[0].label).to eq ["Top!"]
      expect(multi_volume_work.logical_structure[0].nodes[0].label).to eq ["Chapter 1"]
      expect(multi_volume_work.logical_structure[0].nodes[0].nodes[0].proxy).to eq [resource1.id]
      expect(multi_volume_work.logical_structure[0].nodes[1].label).to eq ["Chapter 2"]
      expect(multi_volume_work.logical_structure[0].nodes[1].nodes[0].proxy).to eq [resource2.id]
    end
  end
end
