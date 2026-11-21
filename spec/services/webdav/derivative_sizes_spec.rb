require "rails_helper"

RSpec.describe Webdav::DerivativeSizes do
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:url) { "https://iiif.example.com/iiif/2/abc/full/!2000,2000/0/default.jpg" }
  let(:entry) { Webdav::Entry.new(name: "0001 - a.jpg", derivative_url: url, mtime: Time.zone.at(1_000)) }

  before do
    allow(Rails).to receive(:cache).and_return(cache)
  end

  it "uses Content-Length from a HEAD request, and caches it" do
    stub_request(:head, url).to_return(headers: { "Content-Length" => "1234" })

    expect(described_class.for([entry])).to eq(url => 1234)
    expect(described_class.for([entry])).to eq(url => 1234)
    expect(a_request(:head, url)).to have_been_made.once
  end

  it "renders the image to count it when HEAD has no Content-Length" do
    stub_request(:head, url).to_return(status: 200)
    stub_request(:get, url).to_return(body: "x" * 50)

    expect(described_class.for([entry])).to eq(url => 50)
  end

  it "leaves out sizes it can't get, and tries again next time" do
    stub_request(:head, url).to_return(status: 404).then.to_return(headers: { "Content-Length" => "9" })

    expect(described_class.for([entry])).to eq({})
    expect(described_class.for([entry])).to eq(url => 9)
  end

  it "survives connection errors" do
    stub_request(:head, url).to_raise(Errno::ECONNREFUSED)
    expect(described_class.for([entry])).to eq({})
  end

  it "only reads the cache when not fetching" do
    expect(described_class.for([entry], fetch: false)).to eq({})
    expect(a_request(:head, url)).not_to have_been_made
  end

  it "stops fetching when the time budget runs out" do
    stub_const("Webdav::DerivativeSizes::BUDGET", 0)
    expect(described_class.for([entry])).to eq({})
    expect(a_request(:head, url)).not_to have_been_made
  end

  it "keys the cache on the file's mtime, so a replaced file is re-measured" do
    stub_request(:head, url).to_return(headers: { "Content-Length" => "1" }).then.to_return(headers: { "Content-Length" => "2" })
    described_class.for([entry])
    entry.mtime = Time.zone.at(2_000)
    expect(described_class.for([entry])).to eq(url => 2)
  end

  it "does nothing for no entries" do
    expect(described_class.for([])).to eq({})
  end
end
