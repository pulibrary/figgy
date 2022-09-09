# frozen_string_literal: true
require "rails_helper"

describe BibidUpdater do
  let(:query_service) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

  describe ".update" do
    it "updates voyager bibids" do
      stub_catalog(bib_id: "123456")
      stub_catalog(bib_id: "991234563506421")
      stub_catalog(bib_id: "7214786")
      stub_catalog(bib_id: "99125378001906421")
      stub_findingaid(pulfa_id: "C0652_c0383")
      # Don't stub the call for the Alma version of this bibid to ensure it
      # doesn't refresh metadata.
      r1 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["123456"])
      r2 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["7214786"])
      r3 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["991234563506421"])
      r4 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["C0652_c0383"])
      r5 = FactoryBot.create_for_repository(:scanned_resource)
      # Alma native resource - don't migrate this.
      r6 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["99125378001906421"])

      described_class.update

      r1 = query_service.find_by(id: r1.id.to_s)
      r2 = query_service.find_by(id: r2.id.to_s)
      r3 = query_service.find_by(id: r3.id.to_s)
      r4 = query_service.find_by(id: r4.id.to_s)
      r5 = query_service.find_by(id: r5.id.to_s)
      r6 = query_service.find_by(id: r6.id.to_s)

      expect(r1.source_metadata_identifier).to eq ["991234563506421"]
      expect(r2.source_metadata_identifier).to eq ["9972147863506421"]
      expect(r3.source_metadata_identifier).to eq ["991234563506421"]
      expect(r4.source_metadata_identifier).to eq ["C0652_c0383"]
      expect(r5.source_metadata_identifier).to be_nil
      expect(r6.source_metadata_identifier).to eq ["99125378001906421"]
    end
  end
end
