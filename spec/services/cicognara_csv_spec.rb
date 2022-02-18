# frozen_string_literal: true

require "rails_helper"

RSpec.describe CicognaraCSV do
  describe "#headers" do
    let(:headers) do
      ["digital_cico_number", "label", "manifest", "contributing_library", "owner_call_number",
        "owner_system_number", "other_number", "version_edition_statement", "version_publication_statement",
        "version_publication_date", "additional_responsibility", "provenance", "physical_characteristics",
        "rights", "based_on_original"]
    end

    it "has a list of headers" do
      expect(described_class.headers).to eq(headers)
    end
  end

  describe "#values" do
    before do
      stub_bibdata(bib_id: "2068747")
      stub_ezid(shoulder: "99999/fk4", blade: "4609321")
    end

    let(:col) { FactoryBot.create_for_repository :collection }
    let(:manifest_url) { "http://www.example.com/concern/scanned_resources/#{obj.id}/manifest" }

    context "with a non-Vatican/Cicognara rights statement" do
      let(:values) do
        [["cico:qgb", "Princeton University Library", manifest_url, "Princeton University Library",
          "Oversize NA2810 .H75f", "2068747", "ark:/99999/fk44609321", nil, "Amsterdam: J. Jeansson, 1620",
          "1620", nil, nil, "39 . 30 plates. 30 x 40 cm.", RightsStatements.no_known_copyright.to_s,
          false]]
      end
      let(:obj) do
        FactoryBot.create_for_repository :complete_scanned_resource,
          source_metadata_identifier: ["2068747"],
          member_of_collection_ids: [col.id], import_metadata: true
      end
      before do
        obj
      end
      it "has values" do
        expect(described_class.values(col.id)).to eq(values)
      end
    end

    context "with a Vatican/Cicognara rights statement" do
      let(:obj) do
        FactoryBot.create_for_repository :complete_scanned_resource,
          source_metadata_identifier: ["2068747"],
          rights_statement: ["http://cicognara.org/microfiche_copyright"],
          member_of_collection_ids: [col.id], import_metadata: true
      end
      let(:values) do
        [["cico:qgb", "Microfiche", manifest_url, "Bibliotheca Apostolica Vaticana", "Oversize NA2810 .H75f",
          "cico:qgb", "ark:/99999/fk44609321", nil, "Amsterdam: J. Jeansson, 1620", "1620", nil, nil,
          "39 . 30 plates. 30 x 40 cm.", "http://cicognara.org/microfiche_copyright", true]]
      end
      before do
        obj
      end
      it "has values" do
        expect(described_class.values(col.id)).to eq(values)
      end
    end
  end

  describe "#date" do
    it "returns nil when given an invalid date" do
      expect(described_class.date("invalid_date")).to be_nil
    end
  end
end
