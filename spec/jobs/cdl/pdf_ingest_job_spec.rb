# frozen_string_literal: true

require "rails_helper"

RSpec.describe CDL::PDFIngestJob, run_real_derivatives: true, run_real_characterization: true do
  context "when given a PDF path" do
    it "creates a new resource from it and adds it as a file, adds it to the CDL collection" do
      collection = FactoryBot.create_for_repository(:collection, slug: "cdl", title: "CDL")
      stub_bibdata(bib_id: "123456")
      pdf_path = Rails.root.join("tmp", "test_cdl_in", "ingesting", "123456.pdf")
      FileUtils.mkdir_p(pdf_path.parent) unless File.exist?(pdf_path.parent)
      FileUtils.cp(Rails.root.join("spec", "fixtures", "files", "sample.pdf"), pdf_path)
      query_service = ChangeSetPersister.default.query_service

      described_class.perform_now(file_name: "123456.pdf")

      resource = query_service.find_all_of_model(model: ScannedResource).first
      expect(resource.change_set).to eq "CDL::Resource"
      expect(File.exist?(pdf_path)).to eq false
      expect(resource.depositor).to eq ["cdl_auto_ingest"]
      expect(resource.member_of_collection_ids).to eq [collection.id]
      expect(resource.member_ids).not_to be_blank
    end
  end
  context "when the file doesn't copy to tmp storage" do
    it "doesn't create a resource, and raises an error" do
      allow_any_instance_of(IngestableFile).to receive(:path).and_return(Rails.root.join("tmp", "notafile.pdf").to_s)
      FactoryBot.create_for_repository(:collection, slug: "cdl", title: "CDL")
      stub_bibdata(bib_id: "123456")
      pdf_path = Rails.root.join("tmp", "test_cdl_in", "ingesting", "123456.pdf")
      FileUtils.mkdir_p(pdf_path.parent) unless File.exist?(pdf_path.parent)
      FileUtils.cp(Rails.root.join("spec", "fixtures", "files", "sample.pdf"), pdf_path)
      query_service = ChangeSetPersister.default.query_service

      expect { described_class.perform_now(file_name: "123456.pdf") }.to raise_error "No PDF Found: 123456.pdf"

      resources = query_service.find_all_of_model(model: ScannedResource)
      expect(resources.length).to eq 0
      expect(File.exist?(pdf_path)).to eq true
    end
  end
end
