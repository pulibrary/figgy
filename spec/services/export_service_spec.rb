# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe ExportService do
  let(:query_service) { metadata_adapter.query_service }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:export_path) { Rails.root.join("tmp", "test_export") }

  before do
    FileUtils.rm_rf(export_path) if File.exist?(export_path)
  end

  describe "#export" do
    context "with a scanned resource" do
      let(:file1) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456", files: [file1]) }

      before do
        stub_bibdata(bib_id: "123456")
        described_class.export(scanned_resource)
      end

      it "exports files in a directory" do
        expect(File.exist?("#{export_path}/123456/abstract.tiff")).to be true
      end
    end

    context "with a multi-volume work" do
      let(:file1) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
      let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:vol1) { FactoryBot.create_for_repository(:scanned_resource, title: "first volume", files: [file1]) }
      let(:vol2) { FactoryBot.create_for_repository(:scanned_resource, title: "second volume", files: [file2]) }
      let(:multi_volume_work) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "4609321", member_ids: [vol1.id, vol2.id]) }

      before do
        stub_bibdata(bib_id: "4609321")
        described_class.export(multi_volume_work)
      end

      it "exports each volume in a subdirectory" do
        expect(File.exist?("#{export_path}/4609321/first volume/abstract.tiff")).to be true
        expect(File.exist?("#{export_path}/4609321/second volume/example.tif")).to be true
      end
    end
  end
end
