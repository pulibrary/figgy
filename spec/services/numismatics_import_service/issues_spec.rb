# frozen_string_literal: true
require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe NumismaticsImportService::Issues do
  let(:importer) { described_class.new(db_adapter: db_adapter) }
  let(:db_adapter) { instance_double(NumismaticsImportService::TinyTdsAdapter) }

  describe "#base_query" do
    context "with a sql server adapter" do
      it "returns a query for sql server" do
        expect(importer.base_query(id: "1234")).to include "[Figure Name]"
      end
    end
  end
end
