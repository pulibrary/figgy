# frozen_string_literal: true

require "rails_helper"

RSpec.describe CDL::AutomaticIngester do
  context "when given multiple files, some of which are PDFs" do
    it "queues a background job to ingest each of the PDFs with a valid source metadata identifier that are older than 1 hour" do
      allow(File).to receive(:mtime).and_call_original
      file_path = Pathname.new(Figgy.config["cdl_in_path"])
      FileUtils.mkdir_p(file_path.join("ingesting")) unless File.exist?(file_path.join("ingesting"))
      FileUtils.cp(Rails.root.join("spec", "fixtures", "files", "sample.pdf"), file_path.join("123456.pdf"))
      allow(File).to receive(:mtime).with(file_path.join("123456.pdf").to_s).and_return(1.hour.ago)
      # Recently copied file - don't ingest.
      FileUtils.cp(Rails.root.join("spec", "fixtures", "files", "sample.pdf"), file_path.join("56789.pdf"))
      # Not a bib - don't ingest.
      FileUtils.cp(Rails.root.join("spec", "fixtures", "files", "sample.pdf"), file_path.join("notabib.pdf"))
      # Ensure already ingesting files aren't ingested again.
      FileUtils.cp(Rails.root.join("spec", "fixtures", "files", "sample.pdf"), file_path.join("ingesting", "45678.pdf"))
      FileUtils.cp(Rails.root.join("spec", "fixtures", "files", "example.tif"), file_path.join("123456.tif"))
      allow(CDL::PDFIngestJob).to receive(:perform_later)

      described_class.run

      expect(File.exist?(file_path.join("ingesting", "123456.pdf"))).to eq true
      expect(CDL::PDFIngestJob).to have_received(:perform_later).once
      expect(CDL::PDFIngestJob).to have_received(:perform_later).once.with(file_name: "123456.pdf")
    end

    after do
      FileUtils.rm_rf(Figgy.config["cdl_in_path"])
    end
  end
end