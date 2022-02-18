# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExportPDFJob do
  describe ".perform" do
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
    let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
    let(:export_path) { Rails.root.join("tmp", "test_export") }
    let(:export_service) { class_double("ExportService").as_stubbed_const }

    before do
      FileUtils.rm_rf(export_path) if File.exist?(export_path)
      allow(export_service).to receive(:export_pdf)
    end

    it "exports the object to disk" do
      described_class.perform_now(resource.id)
      expect(export_service).to have_received(:export_pdf).with(having_attributes(id: resource.id))
    end
  end
end
