# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestGeoportalRecordJob do
  describe "integration test" do
    with_queue_adapter :inline
    let(:user) { FactoryBot.build(:admin) }
    let(:fgdc_path) { Rails.root.join("spec", "fixtures", "files", "geo_metadata", "fgdc.xml") }
    let(:base_data_path) { Rails.root.join("spec", "fixtures", "ingest_geoportal").to_s }
    let(:adapter) { Valkyrie.config.metadata_adapter }

    before do
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end

    it "ingests a geoportal record file, extracts from FGDC, and mint a new ARK" do
      described_class.perform_now(fgdc_path: fgdc_path, user: user, base_data_path: base_data_path)

      vector = adapter.query_service.find_all_of_model(model: VectorResource).first
      expect(vector).not_to be_nil
      expect(vector.local_identifier).to eq ["fgdc"]
      expect(vector.title).to eq ["China census data by county, 2000-2010"]
      expect(vector.state).to eq ["complete"]
      expect(vector.identifier).to eq ["ark:/99999/fk4123456"]
      expect(vector.member_ids).not_to be_blank
      file_sets = adapter.query_service.find_members(resource: vector)
      expect(file_sets.count).to eq 2
      expect(file_sets.first.title).to eq ["shapefile.zip"]
      expect(file_sets.first.derivative_file).not_to be_blank
    end

    context "when given an existing ARK value" do
      let(:ark) { "ark:/shoulder/testblade" }

      it "ingests the geoportal record and assigns the ARK value" do
        described_class.perform_now(fgdc_path: fgdc_path, user: user, base_data_path: base_data_path, ark: ark)

        vector = adapter.query_service.find_all_of_model(model: VectorResource).first
        expect(vector.identifier).to eq [ark]
      end
    end

    context "when extracting from fgdc record raises an exception" do
      let(:extractor) { instance_double(GeoMetadataExtractor::Fgdc) }
      before do
        allow(GeoMetadataExtractor::Fgdc).to receive(:new).and_return(extractor)
        allow(extractor).to receive(:extract).and_raise(StandardError, "Fail")
      end

      it "gracefully handles the error and does not apply metadata" do
        described_class.perform_now(fgdc_path: fgdc_path, user: user, base_data_path: base_data_path)

        vector = adapter.query_service.find_all_of_model(model: VectorResource).first
        expect(vector.title).not_to eq ["China census data by county, 2000-2010"]
      end
    end
  end
end
