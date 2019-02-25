# frozen_string_literal: true
require "rails_helper"

RSpec.describe SvnParser do
  subject(:svn) { described_class.new }
  let(:logger) { instance_double Logger }
  let(:success) { instance_double Process::Status }

  before do
    allow(logger).to receive(:info)
    allow(Rails).to receive(:logger).and_return(logger)
    allow(success).to receive(:success?).and_return(true)
  end

  describe "#updated_collection_paths" do
    before do
      allow(Open3).to receive(:capture2)
        .with("svn --username tester --password testing diff --summarize -r {#{Time.zone.yesterday.to_formatted_s(:iso8601)}}:HEAD http://example.com/svn/pulfa/trunk/eads")
        .and_return([svn_diff_fixture, success])
    end

    it "lists updated collection paths" do
      expect(svn.updated_collection_paths(Time.zone.yesterday)).to eq(["mss/C0652.EAD.xml", "mudd/publicpolicy/MC016.EAD.xml"])
    end
  end

  describe "#get_collection" do
    let(:svn_fixture) { "<dummy_ead_xml/>\n" }
    before do
      allow(Open3).to receive(:capture2)
        .with("svn --username tester --password testing cat http://example.com/svn/pulfa/trunk/eads/cotsen/COTSEN1.EAD.xml")
        .and_return(["<dummy/>", success])
    end

    it "retrieves collection EAD XML" do
      expect(svn.get_collection("cotsen/COTSEN1.EAD.xml")).to eq("<dummy/>")
    end
  end

  def svn_diff_fixture
    <<~HEREDOC
      M       http://example.com/svn/pulfa/trunk/eads/mss/C0652.EAD.xml
      M       http://example.com/svn/pulfa/trunk/eads/mudd/publicpolicy/MC016.EAD.xml
    HEREDOC
  end
end
