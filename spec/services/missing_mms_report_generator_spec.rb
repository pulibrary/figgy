# frozen_string_literal: true
require "rails_helper"

describe MissingMmsReportGenerator do
  subject(:generator) { described_class.new(collection_id: collection_id, csv_file: csv_file) }
  let(:collection) { FactoryBot.create_for_repository(:collection) }
  let(:bib_id) { "9946093213506421" }
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: bib_id, member_of_collection_ids: [collection.id]) }
  let(:scanned_resource_2) { FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id]) }
  let(:collection_id) { collection.id.to_s }
  let(:csv_file) { Rails.root.join("tmp", "missing_mms_report.csv") }

  describe "#generate" do
    before do
      FileUtils.rm_f(csv_file)
      stub_catalog(bib_id: bib_id)
      scanned_resource_2
      scanned_resource
      generator.generate
    end

    it "generates the report and writes the report to a CSV file" do
      expect(File.exist?(csv_file)).to be true

      read = CSV.read(csv_file, headers: true, header_converters: :symbol)
      expect(read.length).to eq 1
    end
  end
end
