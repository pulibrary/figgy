require "rails_helper"

RSpec.describe SeleneIndexer do
  describe ".to_solr" do
    it "properly indexes parent title and source metadata indentifier" do
      stub_catalog(bib_id: "991234563506421")
      scanned_resource = FactoryBot.create_for_repository(:scanned_resource_with_selene_resource, source_metadata_identifier: "991234563506421", title: "Resource with Selene")
      file_set = Wayfinder.for(scanned_resource).file_sets.first
      selene_resource = Wayfinder.for(file_set).members.first

      output = described_class.new(resource: selene_resource).to_solr
      expect(output[:parent_title_ssi]).to eq "Resource with Selene"
      expect(output[:source_metadata_identifier_ssim]).to eq ["991234563506421"]
    end
  end
end
