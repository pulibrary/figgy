# frozen_string_literal: true

require "rails_helper"

RSpec.describe CDL::EventLogging do
  describe ".get_patron_group" do
    context "when the connection is succesful" do
      let(:netid) { "abc123" }
      before do
        stub_request(:get, "https://bibdata.princeton.edu/patron/#{netid}")
          .to_return(status: 200,
                     body: file_fixture("bibdata/#{netid}.json").read, headers: { "Content-Type" => "application/json" })
      end
      it "returns the patron group" do
        expect(described_class.get_patron_group(netid: netid)).to eq "staff"
      end
    end

    context "when the connection is not succesful" do
      let(:netid) { "abc123" }
      before do
        stub_request(:get, "https://bibdata.princeton.edu/patron/#{netid}")
          .to_return(status: 404,
                     body: nil, headers: { "Content-Type" => "application/json" })
      end
      it "returns nil" do
        expect(described_class.get_patron_group(netid: netid)).to be_nil
      end
    end
    context "when the connection is a bad uri" do
      let(:netid) { [] }
      it "will not raise an error" do
        expect { described_class.get_patron_group(netid: netid) }.not_to raise_error
      end
    end
  end

  describe ".google_charge_event" do
    let(:netid) { "abc123" }
    let(:bibid) { "12345" }
    before do
      stub_request(:get, "https://bibdata.princeton.edu/patron/#{netid}")
        .to_return(status: 200,
                   body: file_fixture("bibdata/#{netid}.json").read, headers: { "Content-Type" => "application/json" })
      stub_request(:post, "https://www.google-analytics.com/collect")
      allow(SecureRandom).to receive(:uuid).and_return("1")
    end
    it "sends an analytics google charge request" do
      described_class.google_charge_event(source_metadata_identifier: bibid, netid: netid)
      expect(a_request(:post, "https://www.google-analytics.com/collect")
      .with(body: "cid=1&ea=charge&ec=CDL-staff&el=12345&t=event&tid=UA-15870237-29&ua=Figgy&v=1")).to have_been_made
    end
  end
end
