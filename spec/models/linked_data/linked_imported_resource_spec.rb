# frozen_string_literal: true
require "rails_helper"

RSpec.describe LinkedData::LinkedImportedResource do
  let(:linked_resource) { described_class.new(resource: resource) }
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, title: ["more", "than", "one", "title"]) }

  it "returns an array of titles" do
    expect(linked_resource.as_jsonld["title"]).to be_a Array
  end

  it "returns JSON-LD with a system_created_at/system_updated_at date" do
    expect(linked_resource.as_jsonld["system_created_at"]).to be_present
    expect(linked_resource.as_jsonld["system_updated_at"]).to be_present
  end

  context "when it has a bib id" do
    let(:source_id) { "4609321" }
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: source_id) }
    it "returns a link to the catalog" do
      stub_bibdata(bib_id: source_id)
      expect(linked_resource.as_jsonld["link_to_catalog"]).to eq "https://catalog.princeton.edu/catalog/#{source_id}"
    end
  end
  context "when it has a component id" do
    let(:source_id) { "C0652_c0389" }
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: source_id) }
    it "returns a link to the finding aids site" do
      stub_pulfa(pulfa_id: source_id)
      expect(linked_resource.as_jsonld["link_to_finding_aid"]).to eq "https://findingaids.princeton.edu/collections/C0652/c0389"
    end
  end
end
