# frozen_string_literal: true
require "rails_helper"

RSpec.describe Dspace::Downloader do
  let(:handle) { "88435/dsp016q182k16g" }
  let(:token) { "bla" }

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
end
