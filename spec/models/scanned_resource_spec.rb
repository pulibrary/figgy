# frozen_string_literal: true
# Generated with `rails generate valkyrie:model ScannedResource`
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe ScannedResource do
  let(:resource_klass) { described_class }
  let(:resource) { FactoryBot.create :scanned_resource }

  it_behaves_like 'a Valhalla::Resource'

  it "generates read groups with the factory" do
    factory = FactoryBot.build(:complete_private_scanned_resource)
    expect(factory.read_groups).to eq []
  end

  context "with imported metadata" do
    before do
      stub_bibdata(bib_id: "123456")
    end
    it "indexes subject" do
      scanned_resource = FactoryBot.create_for_repository(:pending_scanned_resource, source_metadata_identifier: "123456", import_metadata: true)
      index = Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: scanned_resource)
      expect(index[:display_subject_ssim]).to eq scanned_resource.imported_metadata.first.subject
    end
  end

  describe "#logical_structure" do
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
    let(:resource1) { FactoryBot.create_for_repository(:file_set) }
    let(:resource2) { FactoryBot.create_for_repository(:file_set) }
    it "can set a whole structure all at once" do
      change_set.prepopulate!
      expect(change_set.validate(logical_structure: [structure])).to eq true

      expect(change_set.logical_structure[0].label).to eq ["Top!"]
      expect(change_set.logical_structure[0].nodes[0].label).to eq ["Chapter 1"]
      expect(change_set.logical_structure[0].nodes[0].nodes[0].proxy).to eq [resource1.id]
      expect(change_set.logical_structure[0].nodes[1].label).to eq ["Chapter 2"]
      expect(change_set.logical_structure[0].nodes[1].nodes[0].proxy).to eq [resource2.id]
    end
    it "has a default label" do
      change_set.prepopulate!

      expect(change_set.logical_structure[0].label).to eq ["Logical"]
    end
  end
end
