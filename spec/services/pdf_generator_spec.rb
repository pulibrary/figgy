# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe PDFGenerator do
  with_queue_adapter :inline
  subject(:generator) { described_class.new(resource: resource, storage_adapter: storage_adapter) }
  let(:file) { fixture_file_upload('files/color-landscape.tif', 'image/tiff') }
  let(:resource) do
    FactoryBot.create_for_repository(
      :scanned_resource,
      files: [file],
      holding_location: ["https://bibdata.princeton.edu/locations/delivery_locations/1"],
      title: RDF::Literal.new("Bolʹshevik Tom", language: :en),
      imported_metadata: [{
        creator: "Aḥsāʼī, Aḥmad ibn Zayn al-Dīn, 1753-1826",
        extent: "299 leaves : paper ; 206 x 152 mm. bound to 209 x 153 mm.",
        description: "Ms. codex."
      }]
    )
  end
  let(:file_set) { query_service.find_members(resource: resource).to_a.first }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:persister) { Valkyrie.config.metadata_adapter.persister }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:derivatives) }
  describe "#render" do
    context "when set to gray" do
      before do
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/287,200/0/gray.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-landscape-pdf.jpg")), status: 200)
        file_set.original_file.width = 287
        file_set.original_file.height = 200
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
      end
    end
    context "when it's set to color" do
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file], pdf_type: ['color']) }
      before do
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,287/0/default.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
      end
      it "will do a color PDF" do
        file_node = generator.render
        file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers.first)
        expect(File.exist?(file.io.path)).to eq true
      end
    end
    context "when it's an arabic manifest" do
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file], language: 'ara', title: 'المفاتيح') }
      before do
        stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,287/0/gray.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
      end
      it "renders" do
        file_node = generator.render
        file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers.first)
        expect(File.exist?(file.io.path)).to eq true
      end
    end
  end
end
