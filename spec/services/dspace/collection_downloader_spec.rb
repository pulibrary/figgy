# frozen_string_literal: true

require "rails_helper"

describe Dspace::CollectionDownloader do
  def stub_item(item_number)
    item_url = "https://dataspace.princeton.edu/rest/items/#{item_number}?expand=all"
    item_fixture_path = Rails.root.join("spec", "fixtures", "dspace", "#{item_number}.json")
    item_fixture = File.read(item_fixture_path)
    stub_request(:get, item_url).to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: item_fixture
    )
  end

  subject(:downloader) { described_class.new(handle, token, ark_mapping) }

  let(:item_mms_id) { "9971957363506421" }
  let(:ark_mapping) do
    {
      "88435/dsp012801pg38m" => item_mms_id
    }
  end
  let(:handle) { "88435/dsp016q182k16g" }
  let(:token) { "bla" }
  let(:client) { Dspace::Client.new(handle, token) }

  let(:item_fixture_path) { Rails.root.join("spec", "fixtures", "dspace", "1672.json") }
  let(:item_fixture) { File.read(item_fixture_path) }
  let(:resource_data) { JSON.parse(item_fixture) }
  let(:item) { Dspace::Resource.new(resource_data, client) }

  describe "#find_mms_id" do
    it "finds an MMS ID for an Item" do
      expect(downloader.find_mms_id(item: item)).to eq item_mms_id
    end
  end

  describe "#collection_mms_id" do
    let(:collection_fixture_path) { Rails.root.join("spec", "fixtures", "dspace", "monographic_collection.json") }
    let(:collection_fixture) { File.read(collection_fixture_path) }
    let(:collection_url) { "https://dataspace.princeton.edu/rest/handle/88435/dsp016q182k16g?expand=all" }
    let(:mms_id) { "9971957363506421" }
    let(:ark_mapping) do
      {
        "88435/dsp016q182k16g" => mms_id
      }
    end

    before do
      stub_request(:get, collection_url).to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: collection_fixture
      )
    end

    it "returns the collection MMS ID" do
      expect(downloader.collection_mms_id).to eq mms_id
    end

    context "when the collection has no MMS ID" do
      let(:mms_id) { nil }

      it "returns nil" do
        expect(downloader.collection_mms_id).to be nil
      end
    end
  end

  describe "#collection_title" do
    let(:collection_fixture_path) { Rails.root.join("spec", "fixtures", "dspace", "monographic_collection.json") }
    let(:collection_fixture) { File.read(collection_fixture_path) }
    let(:collection_url) { "https://dataspace.princeton.edu/rest/handle/88435/dsp016q182k16g?expand=all" }
    let(:ark_mapping) do
      {}
    end
    let(:collection_title) { "Monographic reports and papers (Publicly Accessible)" }

    before do
      stub_request(:get, collection_url).to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: collection_fixture
      )
    end

    it "returns the collection title" do
      expect(downloader.collection_title).to eq collection_title
    end

    context "when the collection has no title" do
      let(:collection_fixture) { {}.to_json }

      it "raises an error" do
        expect { downloader.collection_title }.to raise_error(StandardError, /Failed to find the title for Collection:/)
      end
    end
  end

  describe "#collection_dir" do
    let(:collection_fixture_path) { Rails.root.join("spec", "fixtures", "dspace", "monographic_collection.json") }
    let(:collection_fixture) { File.read(collection_fixture_path) }
    let(:collection_url) { "https://dataspace.princeton.edu/rest/handle/88435/dsp016q182k16g?expand=all" }

    context "when the collection has an MMS ID" do
      let(:mms_id) { "9971957363506421" }
      let(:ark_mapping) do
        {
          "88435/dsp016q182k16g" => mms_id
        }
      end
      let(:collection_dir_path) { Rails.root.join("tmp", "dspace_export_test", mms_id) }

      before do
        stub_request(:get, collection_url).to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: collection_fixture
        )
      end

      it "uses the collection MMS ID to generate the dir path" do
        expect(downloader.collection_dir).to be_a(Pathname)
        expect(downloader.collection_dir).to eq collection_dir_path
      end
    end

    context "when the collection has no MMS ID" do
      let(:ark_mapping) do
        {}
      end
      let(:collection_dir) { "Monographic reports and papers (Publicly Accessible)" }
      let(:collection_dir_path) { Rails.root.join("tmp", "dspace_export_test", collection_dir) }

      before do
        stub_request(:get, collection_url).to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: collection_fixture
        )
      end

      it "uses the collection title to generate the dir path" do
        expect(downloader.collection_dir).to be_a(Pathname)
        expect(downloader.collection_dir).to eq collection_dir_path
      end
    end
  end

  describe "#download_item" do
    let(:collection_fixture_path) { Rails.root.join("spec", "fixtures", "dspace", "monographic_collection.json") }
    let(:collection_fixture) { File.read(collection_fixture_path) }
    let(:collection_url) { "https://dataspace.princeton.edu/rest/handle/88435/dsp016q182k16g?expand=all" }

    context "when the collection has an MMS ID" do
      let(:collection_mms_id) { "9971957363506421" }
      let(:ark_mapping) do
        {
          "88435/dsp016q182k16g" => collection_mms_id
        }
      end
      let(:collection_dir_path) { Rails.root.join("tmp", "dspace_export_test", collection_mms_id) }
      let(:bitstream_id) { 3927 }
      # TODO: Why is there an extra slash in the URL?
      let(:bitstream_url) { "https://dataspace.princeton.edu/rest//bitstreams/#{bitstream_id}/retrieve" }
      let(:bitstream_fixture_path) { Rails.root.join("spec", "fixtures", "files", "sample.pdf") }
      let(:bitstream_fixture) { File.read(bitstream_fixture_path) }
      let(:filename) { "dinner tables" }
      let(:item_path) { collection_dir_path.join(item.title) }
      let(:bitstream_path) { item_path.join("#{filename}.pdf") }

      before do
        FileUtils.rm_rf(collection_dir_path)

        stub_request(:get, bitstream_url).to_return(
          status: 200,
          headers: {},
          body: bitstream_fixture
        )
        stub_item("1672")
        stub_request(:get, collection_url).to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: collection_fixture
        )
      end

      after do
        FileUtils.rm_rf(collection_dir_path)
      end

      it "downloads the bitstreams to a directory with the Item title" do
        downloader.download_item(item)
        expect(File.exist?(bitstream_path)).to be true
      end

      context "when a metadata JSON file already exists" do
        let(:metadata_path) { item_path.join("figgy_metadata.json") }

        before do
          FileUtils.mkdir_p(item_path)
          File.write(metadata_path, "{}")
          allow(Rails.logger).to receive(:debug)
        end

        it "does not download the bitstream and logs a message" do
          downloader.download_item(item)

          expect(Rails.logger).to have_received(:debug).with(/Previously downloaded the item/)
        end
      end
    end

    context "when the collection has a MMS ID but there are no bitstreams" do
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
      end

      it "raises an error" do
        expect { downloader.download_item(item) }.to raise_error(StandardError, /Failed to retrieve the bitstreams for/)
      end
    end

    context "when the collection has a MMS ID but there is an error encountered downloading a bitstream" do
      let(:item_number) { 1672 }
      let(:item_url) { "https://dataspace.princeton.edu/rest/items/#{item_number}?expand=all" }
      let(:item_fixture) do
        {
          "id" => item_number,
          "title" => "Travelling across dinner-tables.",
          "type" => "item",
          "handle" => "88435/dsp012801pg38m",
          "link" => "/rest/items/1672",
          "bitstreams" => [
            {
              "id" => 3927,
              "bundleName" => "ORIGINAL",
              "name" => "dinner tables.pdf",
              "retrieveLink" => "bitstreams/3927/retrieve"
            }
          ]
        }.to_json
      end

      before do
        stub_request(:get, "https://dataspace.princeton.edu/rest/bitstreams/3927/retrieve").to_return(
          status: 500
        )
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
      end

      it "raises an error" do
        expect { downloader.download_item(item) }.to raise_error(StandardError, /Failed to download bitstream/)
      end
    end

    context "when the collection does not have an MMS ID" do
      let(:collection_dir) { "Monographic reports and papers (Publicly Accessible)" }
      let(:collection_dir_path) { Rails.root.join("tmp", "dspace_export_test", collection_dir) }
      let(:bitstream_id) { 3927 }
      # TODO: Why is there an extra slash in the URL?
      let(:bitstream_url) { "https://dataspace.princeton.edu/rest//bitstreams/#{bitstream_id}/retrieve" }
      let(:bitstream_fixture_path) { Rails.root.join("spec", "fixtures", "files", "sample.pdf") }
      let(:bitstream_fixture) { File.read(bitstream_fixture_path) }
      let(:filename) { "dinner tables" }
      let(:item_path) { collection_dir_path.join(item_mms_id) }
      let(:bitstream_path) { item_path.join("#{filename}.pdf") }

      before do
        FileUtils.rm_rf(collection_dir_path)

        stub_request(:get, bitstream_url).to_return(
          status: 200,
          headers: {},
          body: bitstream_fixture
        )
        stub_item("1672")
        stub_request(:get, collection_url).to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: collection_fixture
        )
      end

      after do
        FileUtils.rm_rf(collection_dir_path)
      end

      it "downloads the bitstreams to a directory with the Item MMS ID" do
        downloader.download_item(item)
        expect(File.exist?(bitstream_path)).to be true
      end

      context "when the item does not have an MMS ID" do
        let(:item_mms_id) { nil }
        let(:ark_mapping) do
          {}
        end

        before do
          allow(Rails.logger).to receive(:debug)
        end

        it "logs an error and does not download the bitstreams" do
          downloader.download_item(item)
          expect(Rails.logger).to have_received(:debug).with(/Failed to retrieve the MMS ID for #{item.title} \(#{item.handle}\):/)
        end
      end
    end
  end

  describe "#download_all!" do
    let(:collection_fixture_path) { Rails.root.join("spec", "fixtures", "dspace", "monographic_collection.json") }
    let(:collection_fixture) { File.read(collection_fixture_path) }
    let(:collection_url) { "https://dataspace.princeton.edu/rest/handle/88435/dsp016q182k16g?expand=all" }

    context "when the collection has an MMS ID" do
      let(:collection_mms_id) { "9971957363506421" }
      let(:ark_mapping) do
        {
          "88435/dsp016q182k16g" => collection_mms_id
        }
      end
      let(:collection_dir_path) { Rails.root.join("tmp", "dspace_export_test", collection_mms_id) }
      let(:bitstream_url) do
        %r{https://dataspace.princeton.edu/rest//bitstreams/.*/retrieve}
      end
      let(:bitstream_fixture_path) { Rails.root.join("spec", "fixtures", "files", "sample.pdf") }
      let(:bitstream_fixture) { File.read(bitstream_fixture_path) }
      let(:filename) { "dinner tables" }
      let(:item_path) { collection_dir_path.join(item.title) }
      let(:bitstream_path) { item_path.join("#{filename}.pdf") }

      before do
        FileUtils.rm_rf(collection_dir_path)

        stub_request(:get, bitstream_url).to_return(
          status: 200,
          headers: {},
          body: bitstream_fixture
        )
        stub_item("93362")
        stub_item("1672")
        stub_request(:get, collection_url).to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: collection_fixture
        )
      end

      after do
        FileUtils.rm_rf(collection_dir_path)
      end

      it "downloads the bitstreams to a directory with the Item title" do
        downloader.download_all!
        expect(File.exist?(bitstream_path)).to be true
      end
    end
  end
end
