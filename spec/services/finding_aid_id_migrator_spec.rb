# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindingAidIdMigrator do
  describe ".run!" do
    it "migrates the resources from finding aid IDs to MMS IDs" do
      pulfa_id = "C0652_c0377"
      stub_findingaid(pulfa_id: pulfa_id)
      stub_catalog(bib_id: "99100017893506421")
      unmigrated_resource1 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: pulfa_id)
      unmigrated_resource2 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: pulfa_id)
      migrator = described_class.new(csv_path: Rails.root.join("spec", "fixtures", "cid_mmsid_csv.csv"))

      migrator.run!

      migrated_resource1 = ChangeSetPersister.default.query_service.find_by(id: unmigrated_resource1.id)
      migrated_resource2 = ChangeSetPersister.default.query_service.find_by(id: unmigrated_resource2.id)
      expect(migrated_resource1.source_metadata_identifier).to eq ["99100017893506421"]
      expect(migrated_resource2.source_metadata_identifier).to eq ["99100017893506421"]
    end
  end
end
