# frozen_string_literal: true
# Generated with `rails generate valkyrie:model ScannedResource`
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe ScannedResource do
  let(:resource_klass) { described_class }
  let(:resource) { FactoryBot.create :scanned_resource }

  it_behaves_like "a Resource"

  it "generates read groups with the factory" do
    factory = FactoryBot.build(:complete_private_scanned_resource)
    expect(factory.read_groups).to eq []
  end

  context "with imported metadata" do
    let(:scanned_resource) { FactoryBot.create_for_repository(:pending_scanned_resource, source_metadata_identifier: "123456", import_metadata: true) }
    before do
      stub_bibdata(bib_id: "123456")
    end

    it "indexes subject" do
      index = Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: scanned_resource)
      expect(index[:display_subject_ssim]).to eq scanned_resource.imported_metadata.first.subject
    end

    it "imports the location" do
      expect(scanned_resource.primary_imported_metadata.location).to include "RCPPA BL980.G7 B66 1982"
    end
  end
end
