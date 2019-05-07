# frozen_string_literal: true
require "rails_helper"
include ActiveJob::TestHelper

RSpec.describe NumismaticsImportService::Monograms do
  let(:importer) { described_class.new(db_adapter: db_adapter) }
  let(:db_adapter) { instance_double(NumismaticsImportService::TinyTdsAdapter) }

  describe "#ids_query" do
    context "with a sql server adapter" do
      it "returns a query for sql server" do
        expect(importer.ids_query).to include "GROUP BY Filename"
      end
    end
  end

  describe "#base_query" do
    context "with a sql server adapter" do
      it "returns a query for sql server" do
        expect(importer.base_query(id: "1234")).to include "GROUP BY Filename"
      end
    end
  end
end
