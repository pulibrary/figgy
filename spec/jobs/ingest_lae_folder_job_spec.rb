# frozen_string_literal: true

require "rails_helper"

RSpec.describe IngestLaeFolderJob do
  describe "#perform" do
    context "with a set of LAE images" do
      let(:barcode1) { "32101075851400" }
      let(:barcode2) { "32101075851418" }
      let(:lae_dir) { Rails.root.join("spec", "fixtures", "lae") }
      let(:folder1) { FactoryBot.create_for_repository(:ephemera_folder, barcode: [barcode1]) }
      let(:folder2) { FactoryBot.create_for_repository(:ephemera_folder, barcode: [barcode2]) }
      let(:query_service) { metadata_adapter.query_service }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
      before do
        folder1
        folder2
        stub_request(:get, "https://bibdata.princeton.edu/bibliographic/32101075851400/jsonld").and_return(status: 404)
        stub_request(:get, "https://bibdata.princeton.edu/bibliographic/32101075851418/jsonld").and_return(status: 404)
      end

      it "attaches the files" do
        described_class.perform_now(lae_dir)

        reloaded1 = query_service.find_by(id: folder1.id)
        reloaded2 = query_service.find_by(id: folder2.id)

        expect(reloaded1.member_ids.length).to eq 1
        expect(reloaded2.member_ids.length).to eq 2

        file_sets = query_service.find_members(resource: reloaded2)
        expect(file_sets.flat_map(&:title).to_a).to eq ["1", "2"]
      end
    end
  end
end
