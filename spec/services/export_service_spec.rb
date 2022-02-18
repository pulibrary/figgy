# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExportService do
  let(:query_service) { metadata_adapter.query_service }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:export_path) { Rails.root.join("tmp", "test_export") }

  before do
    FileUtils.rm_rf(export_path) if File.exist?(export_path)
    FileUtils.mkdir_p(export_path)
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

  describe "#export_pdf" do
    with_queue_adapter :inline
    context "with a scanned resource" do
      let(:file1) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
      let(:file_set) { query_service.find_members(resource: scanned_resource).to_a.first }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456", files: [file1], pdf_type: ["gray"]) }

      before do
        stub_bibdata(bib_id: "123456")
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/287,/0/gray.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-landscape-pdf.jpg")), status: 200)
        file_set.original_file.width = 287
        file_set.original_file.height = 200
        Valkyrie::MetadataAdapter.find(:indexing_persister).persister.save(resource: file_set)
      end

      it "exports a PDF" do
        described_class.export_pdf(scanned_resource)
        expect(File.exist?("#{export_path}/#{scanned_resource.id}.pdf")).to be true
      end

      it "doesn't export again if the resource hasn't been updated" do
        FileUtils.touch("#{export_path}/#{scanned_resource.id}.pdf")
        mtime = File.mtime("#{export_path}/#{scanned_resource.id}.pdf")
        described_class.export_pdf(scanned_resource)
        expect(File.mtime("#{export_path}/#{scanned_resource.id}.pdf")).to eq mtime
      end
    end
  end
end
