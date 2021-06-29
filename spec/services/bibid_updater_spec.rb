# frozen_string_literal: true
require "rails_helper"

describe BibidUpdater do
  let(:query_service) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

  describe ".update" do
    it "updates voyager bibids in batches" do
      allow(Reindexer).to receive(:reindex_all)
      stub_bibdata(bib_id: "123456")
      stub_bibdata(bib_id: "7214786")
      stub_bibdata(bib_id: "991234563506421")
      r1 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["123456"])
      r2 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["7214786"])
      r3 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: ["991234563506421"])
      r4 = FactoryBot.create_for_repository(:scanned_resource)

      described_class.update(batch_size: 1)

      r1 = query_service.find_by(id: r1.id.to_s)
      r2 = query_service.find_by(id: r2.id.to_s)
      r3 = query_service.find_by(id: r3.id.to_s)
      r4 = query_service.find_by(id: r4.id.to_s)

      expect(r1.source_metadata_identifier).to eq ["991234563506421"]
      expect(r2.source_metadata_identifier).to eq ["9972147863506421"]
      expect(r3.source_metadata_identifier).to eq ["991234563506421"]
      expect(r4.source_metadata_identifier).to be_nil
      expect(Reindexer).to have_received(:reindex_all)
    end
  end
end
