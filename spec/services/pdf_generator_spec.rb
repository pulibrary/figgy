# frozen_string_literal: true
require "rails_helper"

RSpec.describe PDFGenerator do
  with_queue_adapter :inline
  subject(:generator) { described_class.new(resource: resource, storage_adapter: storage_adapter) }
  let(:file) { fixture_file_upload("files/color-landscape.tif", "image/tiff") }
  let(:resource) do
    FactoryBot.create_for_repository(
      :scanned_resource,
      files: [file],
      holding_location: ["https://bibdata.princeton.edu/locations/delivery_locations/1"],
      title: RDF::Literal.new("Bolʹshevik Tom", language: :en),
      imported_metadata: [{
        creator: "مرحبا يا العالم",
        extent: "299 leaves : paper ; 206 x 152 mm. bound to 209 x 153 mm.",
        description: "Ms. codex.",
        language: "ara"
      }]
    )
  end
  let(:file_set) { query_service.find_members(resource: resource).to_a.first }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:persister) { Valkyrie.config.metadata_adapter.persister }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:derivatives) }
  describe "#render" do
    context "when an error is encountered while downloading" do
      before do
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/gray.jpg").to_return(status: 500)
        allow(Valkyrie.logger).to receive(:error)
      end
      it "raises a PDFGeneratorError and logs an error for each attempted download" do
        expect { generator.render }.to raise_error(PDFGenerator::Error)
        # rubocop:disable Layout/LineLength
        expect(Valkyrie.logger).to have_received(:error).exactly(5).times.with("PDFGenerator: Failed to download a PDF using the following URI as a base: http://www.example.com/image-service/#{file_set.id}/full/200,/0/gray.jpg: 500 ")
        # rubocop:enable Layout/LineLength
      end
    end

    context "when a IIIF Manifest does not have a width" do
      let(:manifest) do
        {
          "@type" => "sc:Manifest",
          "sequences" => [
            {
              "@type" => "sc:Sequence",
              "@id" => "http://www.example.com/concern/scanned_resources/c240f04d-d779-45ad-b7e4-acb28e7b8da6/manifest/sequence/normal",
              "canvases" => [
                {
                  "@type" => "sc:Canvas",
                  "images" => [
                    {
                      "@type" => "oa:Annotation",
                      "motivation" => "sc:painting",
                      "resource" => {
                        "@type" => "dctypes:Image",
                        "@id" => "http://www.example.com/image-service/9292c8c2-8480-42b7-8714-e7e6b45a3bee/full/!1000,/0/default.jpg",
                        "height" => 200
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      let(:manifest_builder) { instance_double(ManifestBuilder) }

      before do
        stub_request(
          :any,
          "http://www.example.com/image-service/#{file_set.id}/full/287,/0/gray.jpg"
        ).to_return(
          body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-landscape-pdf.jpg")),
          status: 200
        )

        file_set.original_file.width = 287
        file_set.original_file.height = 200

        persister.save(resource: file_set)

        allow(Valkyrie.logger).to receive(:error)
        allow(manifest_builder).to receive(:build).and_return(manifest)
        allow(ManifestBuilder).to receive(:new).and_return(manifest_builder)
      end

      it "logs the error" do
        expect { generator.render }.to raise_error(PDFGenerator::Error)
        expect(Valkyrie.logger).to have_received(:error).with("PDFGenerator: Failed to generate a PDF for the resource #{resource.id}: IIIF Manifest image does not specify a width")
      end
    end

    context "when a IIIF Manifest does not have a height" do
      let(:manifest) do
        {
          "@type" => "sc:Manifest",
          "sequences" => [
            {
              "@type" => "sc:Sequence",
              "@id" => "http://www.example.com/concern/scanned_resources/c240f04d-d779-45ad-b7e4-acb28e7b8da6/manifest/sequence/normal",
              "canvases" => [
                {
                  "@type" => "sc:Canvas",
                  "images" => [
                    {
                      "@type" => "oa:Annotation",
                      "motivation" => "sc:painting",
                      "resource" => {
                        "@type" => "dctypes:Image",
                        "@id" => "http://www.example.com/image-service/9292c8c2-8480-42b7-8714-e7e6b45a3bee/full/!1000,/0/default.jpg",
                        "width" => 287
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      let(:manifest_builder) { instance_double(ManifestBuilder) }

      before do
        stub_request(
          :any,
          "http://www.example.com/image-service/#{file_set.id}/full/287,/0/gray.jpg"
        ).to_return(
          body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-landscape-pdf.jpg")),
          status: 200
        )

        file_set.original_file.width = 287
        file_set.original_file.height = 200

        persister.save(resource: file_set)

        allow(Valkyrie.logger).to receive(:error)
        allow(manifest_builder).to receive(:build).and_return(manifest)
        allow(ManifestBuilder).to receive(:new).and_return(manifest_builder)
      end

      it "logs the error" do
        expect { generator.render }.to raise_error(PDFGenerator::Error)
        expect(Valkyrie.logger).to have_received(:error).with("PDFGenerator: Failed to generate a PDF for the resource #{resource.id}: IIIF Manifest image does not specify a height")
      end
    end

    context "when a IIIF Manifest does not have a canvas image resource referenced" do
      let(:manifest) do
        {
          "@type" => "sc:Manifest",
          "sequences" => [
            {
              "@type" => "sc:Sequence",
              "@id" => "http://www.example.com/concern/scanned_resources/c240f04d-d779-45ad-b7e4-acb28e7b8da6/manifest/sequence/normal",
              "canvases" => [
                {
                  "@type" => "sc:Canvas",
                  "images" => [
                    {
                      "@type" => "oa:Annotation",
                      "motivation" => "sc:painting"
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      let(:manifest_builder) { instance_double(ManifestBuilder) }

      before do
        stub_request(
          :any,
          "http://www.example.com/image-service/#{file_set.id}/full/287,/0/gray.jpg"
        ).to_return(
          body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-landscape-pdf.jpg")),
          status: 200
        )

        file_set.original_file.width = 287
        file_set.original_file.height = 200

        persister.save(resource: file_set)

        allow(Valkyrie.logger).to receive(:error)
        allow(manifest_builder).to receive(:build).and_return(manifest)
        allow(ManifestBuilder).to receive(:new).and_return(manifest_builder)
      end

      it "logs the error" do
        expect { generator.render }.to raise_error(PDFGenerator::Error)
        expect(Valkyrie.logger).to have_received(:error).with("PDFGenerator: Failed to generate a PDF for the resource #{resource.id}: IIIF Manifest image does not reference a resource")
      end
    end

    context "when set to gray" do
      before do
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/287,/0/gray.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-landscape-pdf.jpg")), status: 200)
        stub_request(:any, "http://www.example.com/concern/file_sets/#{file_set.id}/text")
          .to_return(body: "Test Text", status: 200)
        file_set.original_file.width = 287
        file_set.original_file.height = 200
        file_set.ocr_content = "Test Text"
        persister.save(resource: file_set)
      end
      it "renders a PDF" do
        file_node = generator.render
        file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers.first)
        expect(File.exist?(file.io.path)).to eq true

        pdf_reader = PDF::Reader.new(file.io.path)
        expect(pdf_reader.page_count).to eq 2 # Including cover page
        expect(pdf_reader.pages.first.orientation).to eq "portrait"
        expect(pdf_reader.pages.last.orientation).to eq "landscape"
        expect(pdf_reader.pages.last.text).to eq "Test Text"
      end
    end
    context "when it's set to color" do
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file], pdf_type: ["color"]) }
      before do
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/default.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
      end
      it "will do a color PDF" do
        file_node = generator.render
        file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers.first)
        expect(File.exist?(file.io.path)).to eq true
      end
    end
    context "when it's an arabic manifest" do
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file], language: "ara", title: "المفاتيح") }
      before do
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/gray.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
      end
      it "renders" do
        file_node = generator.render
        file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers.first)
        expect(File.exist?(file.io.path)).to eq true
      end
    end
    context "when it's a simple resource" do
      let(:resource) { FactoryBot.create_for_repository(:simple_resource, files: [file], pdf_type: ["color"]) }
      before do
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/default.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
      end
      it "renders" do
        file_node = generator.render
        file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers.first)
        expect(File.exist?(file.io.path)).to eq true
      end
    end

    context "when a resource is complete and has an ARK for identifier" do
      let(:resource) { FactoryBot.create_for_repository(:complete_open_scanned_resource, files: [file], pdf_type: ["color"], identifier: "ark:/99999/fk4") }
      let(:shoulder) { "99999" }
      let(:blade) { "fk4" }
      let(:ark) { instance_double(Ark) }

      before do
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/default.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
        stub_ezid(shoulder: shoulder, blade: blade)
        allow(Ark).to receive(:new).and_return(ark)
        allow(ark).to receive(:uri)
      end

      it "generates ARK links in the cover page" do
        file_node = generator.render
        file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers.first)
        expect(File.exist?(file.io.path)).to eq true
        expect(Ark).to have_received(:new).with("ark:/99999/fk4").at_least(:once)
        expect(ark).to have_received(:uri).at_least(:once)
      end
    end

    context "when a resource is complete and has no ARK" do
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file], pdf_type: ["color"], source_metadata_identifier: "123456") }

      before do
        stub_bibdata(bib_id: "123456")
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/default.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
        allow(IdentifierService).to receive(:url_for).and_call_original
      end

      it "generates catalog or finding aid links in the cover page" do
        file_node = generator.render
        file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers.first)
        expect(File.exist?(file.io.path)).to eq true
        expect(IdentifierService).to have_received(:url_for)
      end
    end

    context "with an ephemera folder" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, files: [file], pdf_type: ["color"]) }

      before do
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/default.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
        allow(IdentifierService).to receive(:url_for).and_call_original
      end

      it "generates a figgy link in the cover page" do
        file_node = generator.render
        file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers.first)
        expect(File.exist?(file.io.path)).to eq true
        expect(IdentifierService).to have_received(:url_for)
      end
    end

    context "with a coin" do
      let(:resource) { FactoryBot.create_for_repository(:coin, files: [file], pdf_type: ["color"]) }

      before do
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/default.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
        allow(IdentifierService).to receive(:url_for).and_call_original
      end

      it "generates a figgy link in the cover page" do
        file_node = generator.render
        file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers.first)
        expect(File.exist?(file.io.path)).to eq true
        expect(IdentifierService).to have_received(:url_for)
      end
    end
  end
end
