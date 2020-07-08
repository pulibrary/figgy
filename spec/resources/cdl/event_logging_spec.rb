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
  end
end
