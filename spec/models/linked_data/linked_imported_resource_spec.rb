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
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: source_id, member_of_collection_ids: [collection.id]) }
    it "returns a link to the catalog" do
      stub_bibdata(bib_id: source_id)
      expect(linked_resource.as_jsonld["link_to_catalog"]).to eq "https://catalog.princeton.edu/catalog/#{source_id}"
      expect(linked_resource.as_jsonld["member_of_collections"]).to be_nil
    end
  end

  context "when it has a component id" do
    let(:source_id) { "C0652_c0389" }
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:resource) do
      FactoryBot.create_for_repository(
        :scanned_resource,
        source_metadata_identifier: source_id,
        import_metadata: true,
        member_of_collection_ids: [collection.id]
      )
    end
    it "returns a link to the finding aids site" do
      stub_findingaid(pulfa_id: source_id)
      expect(linked_resource.as_jsonld["link_to_finding_aid"]).to eq "https://findingaids.princeton.edu/collections/C0652/c0389"
    end
    it "has all the imported metadata" do
      stub_findingaid(pulfa_id: source_id)
      jsonld = linked_resource.as_jsonld
      expect(jsonld["created"]).to eq ["1-1"]
      expect(jsonld["date_created"]).to eq ["undated"]
      expect(jsonld["extent"]).to eq ["1 item"]
      expect(jsonld["creator"]).to eq ["Rodriguez Monegal, Emir, 1921-1985."]
      expect(jsonld["language"]).to eq ["Spanish; Castilian"]
      expect(jsonld["publisher"]).to eq ["Rodríguez Monegal, Emír"]
      expect(jsonld["container"]).to eq ["Box 23, Item 4"]
      expect(jsonld["archival_collection_code"]).to be_nil
      expect(jsonld["pdf_type"]).to be_nil
      expect(jsonld["source_metadata_identifier"]).to be_nil
      expect(jsonld["created_at"]).to be_nil
      expect(jsonld["updated_at"]).to be_nil
      expect(jsonld["member_of_collections"]).to be_nil
      collection_json = jsonld["memberOf"].find { |x| x["title"] == collection.title.first }
      expect(collection_json).to eq(
        "@id" => "http://www.example.com/catalog/#{collection.id}",
        "@type" => "pcdm:Collection",
        "title" => collection.title.first
      )
    end
  end
end
