# frozen_string_literal: true
require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe NumismaticsImportService::People do
  let(:importer) { described_class.new(db_adapter: db_adapter) }
  let(:db_adapter) { instance_double(NumismaticsImportService::TinyTdsAdapter) }

  describe "#combined_query" do
    context "with a sql server adapter" do
      it "returns a query for sql server" do
        expect(importer.combined_query).to include("PersonID AS VARCHAR(16)", "(RulerID AS VARCHAR(16)")
      end
    end
  end
end
