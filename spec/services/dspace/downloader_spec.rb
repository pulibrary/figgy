# frozen_string_literal: true
require "rails_helper"

RSpec.describe Dspace::Downloader do
  subject(:downloader) { described_class.new(handle, token, ark_mapping) }

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

  let(:download_path) { Pathname.new(Figgy.config["dspace"]["download_path"]) }

  before do
    stub_request(:get, "https://dataspace.princeton.edu/rest/handle/88435/dsp016q182k16g?expand=all")
      .to_return(status: 200, body: File.read(Rails.root.join("spec", "fixtures", "dspace", "monographic_collection.json")), headers: { "Content-Type" => "application/json" })
    stub_item("1672")
    stub_item("93362")
    stub_request(:get, %r{https://dataspace.princeton.edu/rest/bitstreams/.*/retrieve})
      .to_return(status: 200, body: File.open(Rails.root.join("spec", "fixtures", "files", "sample.pdf")), headers: {})
    FileUtils.rm_rf(download_path)
  end

  context "when a resource has items" do
    it "downloads all items" do
      downloader = described_class.new(handle, token, { "88435/dsp012801pg38m" => "9971957363506421" })
      downloader.download_all!

      # Single PDF, mapped
      expect(File.exist?(download_path.join("dsp016q182k16g/mapped/9971957363506421/dinner tables.pdf"))).to eq true
      expect(Dir.glob("#{download_path.join('dsp016q182k16g/mapped/9971957363506421')}/*").length).to eq 2 # figgy_metadata.json and one pdf

      # Multiple PDFs, unmapped
      unmapped_item_dir = download_path.join("dsp016q182k16g/unmapped/dsp01h989r5980")
      expect(Dir.glob(unmapped_item_dir.join("*")).length).to eq 24 # 23 PDFs, one figgy_metadata.json
      expect(unmapped_item_dir.children.sort.first.basename.to_s).to eq "001 - National"
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

      context "when the Item has already been downloaded" do
        let(:unmapped_path) { download_path.join("#{collection_assigned_name}/unmapped/#{item_assigned_name}") }
        let(:metadata_path) { unmapped_path.join("figgy_metadata.json") }
        let(:mapped_path) { download_path.join("#{collection_assigned_name}/mapped/#{item_mms_id}") }
        let(:mapped_metadata_path) { mapped_path.join("figgy_metadata.json") }

        before do
          FileUtils.rm_rf(mapped_path)
          FileUtils.rm_rf(unmapped_path)

          FileUtils.mkdir_p(unmapped_path)
          File.write(metadata_path, "{}")

          allow(Rails.logger).to receive(:debug)
        end

        after do
          FileUtils.rm_rf(unmapped_path)
        end

        it "moves the existing item to the mapped directory" do
          downloader.download_item(item)

          expect(File.exist?(metadata_path)).to be false
          expect(File.exist?(mapped_metadata_path)).to be true

          expect(Rails.logger).to have_received(:debug).with(/Moving previously unmapped/)
        end
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
      let(:bitstream_path) { download_path.join("#{collection_assigned_name}/unmapped/#{item_assigned_name}") }

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

        allow(Rails.logger).to receive(:debug)
      end

      it "logs a debug message" do
        downloader.download_item(item)

        expect(Rails.logger).to have_received(:debug).with(/No bitstreams for /)
        expect(File.exist?(bitstream_path)).to be false
      end
    end
  end
end
