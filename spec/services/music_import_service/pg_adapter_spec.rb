# frozen_string_literal: true
require "rails_helper"

# This test really doesn't do much beyond keep our coverage up
RSpec.describe MusicImportService::PgAdapter do
  let(:adapter) { described_class.new(dbhost: nil, dbport: nil, dbname: nil, dbuser: nil, dbpass: nil) }
  let(:connection) { instance_double PG::Connection }
  let(:result) { instance_double PG::Result }
  before do
    allow(PG).to receive(:connect).and_return(connection)
    allow(connection).to receive(:exec).and_return(result)
    allow(result).to receive(:to_a).and_return([])
  end

  describe "#execute" do
    it "returns an array" do
      expect(adapter.execute(query: "an actual SQL query")).to eq []
    end
  end
end
