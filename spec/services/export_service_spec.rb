# frozen_string_literal: true
require "rails_helper"

RSpec.describe ExportService do
  let(:query_service) { metadata_adapter.query_service }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:export_path) { Pathname.new(Figgy.config["export_base"]) }

  before do
    FileUtils.rm_rf(export_path) if File.exist?(export_path)
    FileUtils.mkdir_p(export_path)
  end

  describe "#export" do
    context "with a scanned resource" do
      let(:file1) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "991234563506421", files: [file1]) }

      before do
        stub_catalog(bib_id: "991234563506421")
        described_class.export(scanned_resource)
      end

      it "exports files in a directory" do
        expect(File.exist?("#{export_path}/991234563506421/abstract.tiff")).to be true
      end
    end

    context "with an ephemera folder with a long name" do
      let(:file1) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
      let(:title) do
        "Contra el PRO: el kirchnerismo y Lousteau no son opción. Cambia por la izquierda. José Castillo (vice jefe de gobierno). Laura Morrone (legisladora). "
      end
      let(:clean_title) do
        "Contra el PRO el kirchnerismo y Lousteau no son opción Cambia por la izquierda José Castillo vice jefe de gobierno Laura Morrone legisladora"
      end
      let(:folder) { FactoryBot.create_for_repository(:ephemera_folder, title: title, files: [file1]) }

      it "exports files in a directory" do
        described_class.export(folder)

        expect(File.exist?("#{export_path}/#{clean_title}/abstract.tiff")).to be true
      end
    end

    context "with a multi-volume work" do
      let(:file1) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
      let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:vol1) { FactoryBot.create_for_repository(:scanned_resource, title: "first volume", files: [file1]) }
      let(:vol2) { FactoryBot.create_for_repository(:scanned_resource, title: "second volume", files: [file2]) }
      let(:multi_volume_work) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "9946093213506421", member_ids: [vol1.id, vol2.id]) }

      before do
        stub_catalog(bib_id: "9946093213506421")
        described_class.export(multi_volume_work)
      end

      it "exports each volume in a subdirectory" do
        expect(File.exist?("#{export_path}/9946093213506421/first volume/abstract.tiff")).to be true
        expect(File.exist?("#{export_path}/9946093213506421/second volume/example.tif")).to be true
      end
    end
  end

  describe "#export_pdf" do
    with_queue_adapter :inline
    context "with a scanned resource" do
      let(:file1) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
      let(:file_set) { query_service.find_members(resource: scanned_resource).to_a.first }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "991234563506421", files: [file1], pdf_type: ["gray"]) }

      before do
        stub_catalog(bib_id: "991234563506421")
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/287,/0/gray.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-landscape-pdf.jpg")), status: 200)
        file_set.primary_file.width = 287
        file_set.primary_file.height = 200
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
