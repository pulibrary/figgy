# frozen_string_literal: true
require "rails_helper"

RSpec.describe Dspace::Downloader do
  subject(:downloader) { described_class.new(collection_handle: handle, dspace_token: token, ark_mapping: ark_mapping) }

  let(:handle) { "88435/dsp016q182k16g" }
  let(:token) { "bla" }
  let(:ark_mapping) { nil }

  let(:client) { Dspace::Client.new(handle, token) }

  let(:item_fixture_path) { Rails.root.join("spec", "fixtures", "dspace", "1672.json") }
  let(:item_fixture) { File.read(item_fixture_path) }
  let(:resource_data) { JSON.parse(item_fixture) }
  let(:item) { Dspace::Resource.new(resource_data, client) }

  let(:collection_fixture_path) { Rails.root.join("spec", "fixtures", "dspace", "monographic_collection.json") }
  let(:collection_fixture) { File.read(collection_fixture_path) }
  let(:collection_assigned_name) { "dsp016q182k16g" }
  let(:collection_url) { "https://dataspace.princeton.edu/rest/handle/88435/#{collection_assigned_name}?expand=all" }
  let(:item_assigned_name) { "dsp012801pg38m" }
  let(:item_handle) { "88435/#{item_assigned_name}" }
  let(:item_mms_id) { "9971957363506421" }

  def stub_item(item_number)
    stub_request(:get, "https://dataspace.princeton.edu/rest/items/#{item_number}?expand=all")
      .to_return(status: 200, body: File.read(Rails.root.join("spec", "fixtures", "dspace", "#{item_number}.json")), headers: { "Content-Type" => "application/json" })
  end

  def stub_collection(item_number)
    stub_request(:get, "https://dataspace.princeton.edu/rest/collections/#{item_number}?expand=all")
      .to_return(status: 200, body: File.read(Rails.root.join("spec", "fixtures", "dspace", "#{item_number}.json")), headers: { "Content-Type" => "application/json" })
  end

  let(:download_path) { Pathname.new(Figgy.config["dspace"]["download_path"]) }

  before do
    stub_request(:get, "https://dataspace.princeton.edu/rest/handle/88435/dsp016q182k16g?expand=all")
      .to_return(status: 200, body: File.read(Rails.root.join("spec", "fixtures", "dspace", "monographic_collection.json")), headers: { "Content-Type" => "application/json" })
    stub_item("1672")
    stub_item("2595")
    stub_item("93362")
    stub_request(:get, %r{https://dataspace.princeton.edu/rest/bitstreams/.*/retrieve})
      .to_return(status: 200, body: File.open(Rails.root.join("spec", "fixtures", "files", "sample.pdf")), headers: {})
    FileUtils.rm_rf(download_path)
  end

  context "when a resource has items" do
    it "skips any items it fails on, emptying the directory" do
      stub_request(:get, "https://dataspace.princeton.edu/rest/bitstreams/6113/retrieve")
        .to_return(status: 400, headers: {})
      allow(Rails.logger).to receive(:info)
      downloader = described_class.new(collection_handle: handle, dspace_token: token, ark_mapping: { "88435/dsp012801pg38m" => "9971957363506421" })
      downloader.download_all!

      expect(Rails.logger).to have_received(:info).with(/Failed to download 88435\/dsp01tx31qh74p/)
      item_dir = download_path.join("dsp016q182k16g/Recenseamento do Brazil em 1872")
      expect(File.exist?(item_dir)).to eq true

      item_dir = download_path.join("dsp016q182k16g/Sistematización de-buenas prácticas en materia de")
      expect(File.exist?(item_dir)).to eq false
    end

    it "downloads all items" do
      downloader = described_class.new(collection_handle: handle, dspace_token: token, ark_mapping: { "88435/dsp012801pg38m" => "9971957363506421" })
      downloader.download_all!

      # Single PDF
      expect(File.exist?(download_path.join("dsp016q182k16g/9971957363506421/dinner tables.pdf"))).to eq true
      expect(Dir.glob("#{download_path.join('dsp016q182k16g/9971957363506421')}/*").length).to eq 2 # figgy_metadata.json and one pdf

      # Multiple PDFs - no mapping, so use title.
      item_dir = download_path.join("dsp016q182k16g/Recenseamento do Brazil em 1872")
      expect(Dir.glob(item_dir.join("*")).length).to eq 24 # 23 PDFs, one figgy_metadata.json
      expect(item_dir.children.sort.first.basename.to_s).to eq "001 - -T-Nati-onal"
      # Handle slashes in the description
      file = item_dir.join("001 - -T-Nati-onal/DSBrazilCensus1872v1National.pdf")
      expect(File.exist?(file)).to eq true
      figgy_metadata = item_dir.join("001 - -T-Nati-onal/figgy_metadata.json")
      content = JSON.parse(File.read(figgy_metadata.to_s))
      expect(content["title"]).to eq "[T]Nati/onal"

      # Ensure the figgy_metadata.json has the appropriate info.
      figgy_metadata = item_dir.join("figgy_metadata.json")
      content = JSON.parse(File.read(figgy_metadata.to_s))
      expect(content["identifier"]).to eq "http://arks.princeton.edu/ark:/88435/dsp01h989r5980"
      # Include DSpace IDs so we can backtrack later if we must.
      expect(content["local_identifier"]).to eq ["88435/dsp01h989r5980", "93362"]

      # Ensure files with slashes get handled and that long names are truncated.
      item_dir = download_path.join("dsp016q182k16g/Sistematización de-buenas prácticas en materia de")
      expect(Dir.glob(item_dir.join("*")).length).to eq 2 # 1 PDF, one figgy_metadata.json
      # Ensure the figgy_metadata.json has the full un-truncated title
      figgy_metadata = item_dir.join("figgy_metadata.json")
      content = JSON.parse(File.read(figgy_metadata.to_s))
      expect(content["title"]).to eq "Sistematización de/buenas prácticas en materia de Educación. / Ciudadana Intercultural para los Pueblos Indígenas de América Latina en contextos de pobreza"
    end
  end

  context "when a resource has collections" do
    let(:handle) { "88435/dsp01kh04dp74g" }
    let(:token) { "bla" }
    before do
      stub_request(:get, "https://dataspace.princeton.edu/rest/handle/88435/dsp01kh04dp74g?expand=all")
        .to_return(status: 200, body: File.read(Rails.root.join("spec", "fixtures", "dspace", "serials_collection.json")), headers: { "Content-Type" => "application/json" })
      stub_collection("2186")
      stub_item("88499")
      stub_item("88496")
    end
    it "downloads all sub-collections as MVW resources" do
      downloader = described_class.new(collection_handle: handle, dspace_token: token, ark_mapping: { "88435/dsp01kd17cw508" => "99103970043506421" })
      downloader.download_all!

      # Ensure the full title is in the figgy_metadata.json
      figgy_metadata = download_path.join("dsp01kh04dp74g/Serials and series reports (Publicly Accessible) -/figgy_metadata.json")
      expect(File.exist?(figgy_metadata)).to eq true
      content = JSON.parse(File.read(figgy_metadata.to_s))
      expect(content["title"]).to eq "Serials and series reports (Publicly Accessible) - 28 Too Many FGM Country Profiles"
      # Serials and series reports (Publicly Accessible) (collection)  // Serials and series reports (Publicly Accessible) - 28 Too Many FGM Country Profiles // Item
      expect(File.exist?(download_path.join("dsp01kh04dp74g/Serials and series reports (Publicly Accessible) -/99103970043506421/TheGambia_2015.pdf"))).to eq true
      # Single PDF, mapped
      expect(File.exist?(download_path.join("dsp01kh04dp74g/Serials and series reports (Publicly Accessible) -/99103970043506421/TheGambia_2015.pdf"))).to eq true
      figgy_metadata = download_path.join("dsp01kh04dp74g/Serials and series reports (Publicly Accessible) -/99103970043506421/figgy_metadata.json")
      expect(File.exist?(figgy_metadata)).to eq true
      content = JSON.parse(File.read(figgy_metadata.to_s))
      expect(content["identifier"]).to eq "http://arks.princeton.edu/ark:/88435/dsp01kd17cw508"
      # Include DSpace IDs so we can backtrack later if we must.
      expect(content["local_identifier"]).to eq ["88435/dsp01kd17cw508", "88499"]

      # Single PDF, unmapped
      item_path = download_path.join("dsp01kh04dp74g/Serials and series reports (Publicly Accessible) -/Country Profile: FGM in Senegal, 2015")
      file_path = item_path.join("Senegal_2015.pdf")
      figgy_metadata = item_path.join("figgy_metadata.json")

      expect(File.exist?(file_path)).to eq true
      expect(File.exist?(figgy_metadata)).to eq true
      content = JSON.parse(File.read(figgy_metadata.to_s))
      expect(content["identifier"]).to eq "http://arks.princeton.edu/ark:/88435/dsp01q524jr415"
      # Include DSpace IDs so we can backtrack later if we must.
      expect(content["local_identifier"]).to eq ["88435/dsp01q524jr415", "88496"]
    end
  end

  describe "#ark_mapping" do
    it "builds the mapping from ARKs to MMS IDs" do
      output = downloader.ark_mapping
      expect(output).to be_a(Hash)
      expect(output).to have_key(item_handle)
      expect(output[item_handle]).to include(item_mms_id)
    end
  end

  describe "#download_item" do
    context "when the Item is mapped to a MMS ID" do
      let(:ark_mapping) do
        {
          item_handle => item_mms_id
        }
      end
    end

    context "when the Item has been downloaded after it was mapped to a MMS ID" do
      let(:mapped_path) { download_path.join("#{collection_assigned_name}/#{item_mms_id}") }
      let(:mapped_metadata_path) { mapped_path.join("figgy_metadata.json") }

      before do
        FileUtils.rm_rf(mapped_path)

        FileUtils.mkdir_p(mapped_path)
        File.write(mapped_metadata_path, "{}")
      end

      after do
        FileUtils.rm_rf(mapped_path)
      end

      it "does not download the bitstream" do
        downloader.download_item(item)

        expect(File.exist?(mapped_metadata_path)).to be true
        expect(WebMock).not_to have_requested(:get, %r{https://dataspace.princeton.edu/rest/bitstreams/.*/retrieve})
      end
    end

    context "when there are no bitstreams" do
      let(:item_number) { 1672 }
      let(:item_url) { "https://dataspace.princeton.edu/rest/items/#{item_number}?expand=all" }
      let(:item_fixture) do
        {
          "id" => item_number,
          "title" => "Travelling across dinner-tables.",
          "type" => "item",
          "handle" => "88435/dsp012801pg38m",
          "lastModified" => "2012-10-07 02:01:57.234",
          "link" => "/rest/items/1672",
          "bitstreams" => [],
          "archived" => "true",
          "withdrawn" => "false"
        }.to_json
      end
      let(:bitstream_path) { download_path.join("#{collection_assigned_name}/Travelling across dinner-tables.") }

      before do
        stub_request(:get, item_url).to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: item_fixture
        )

        stub_request(:get, collection_url).to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: collection_fixture
        )

        allow(Rails.logger).to receive(:info)
      end

      it "logs a debug message" do
        downloader.download_item(item)

        expect(Rails.logger).to have_received(:info).with(/No bitstreams for /)
        expect(File.exist?(bitstream_path)).to be false
      end
    end
  end
end
