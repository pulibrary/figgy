# frozen_string_literal: true
require "rails_helper"

RSpec.describe SvnParser do
  subject(:svn) { described_class.new }
  let(:success) { instance_double Process::Status }

  before do
    allow(success).to receive(:success?).and_return(true)
  end

  describe "#all_collection_paths" do
    let(:svn_fixture) { "build.xml\ncotsen/\ncotsen/COTSEN1.EAD.xml\ncotsen/COTSEN2.EAD.xml\n" }
    before do
      allow(Open3).to receive(:capture2)
        .with("svn --username tester --password testing list --recursive http://example.com/svn/pulfa/trunk/eads")
        .and_return([svn_fixture, success])
    end

    it "lists collection paths" do
      expect(svn.all_collection_paths).to eq(["cotsen/COTSEN1.EAD.xml", "cotsen/COTSEN2.EAD.xml"])
    end
  end

  describe "#get_collection" do
    let(:svn_fixture) { "<dummy_ead_xml/>\n" }
    before do
      allow(Open3).to receive(:capture2)
        .with("svn --username tester --password testing cat http://example.com/svn/pulfa/trunk/eads/cotsen/COTSEN1.EAD.xml")
        .and_return([svn_fixture, success])
    end

    it "retrieves collection EAD XML" do
      expect(svn.get_collection("cotsen/COTSEN1.EAD.xml")).to eq(svn_fixture)
    end
  end
end
