# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::AccessionDateMigrator do
  describe ".call" do
    context "when an accession has a nil date" do
      it "stays nil" do
        accession = FactoryBot.create_for_repository(:numismatic_accession, date: nil)
        described_class.call
        query_service = Valkyrie.config.metadata_adapter.query_service
        expect(query_service.find_by(id: accession.id).date).to be_nil
      end
    end

    context "when an accession has a correctly formatted (YYYY-MM-DD) date" do
      it "doesn't change" do
        accession = FactoryBot.create_for_repository(:numismatic_accession, date: "2001-01-01")
        described_class.call
        query_service = Valkyrie.config.metadata_adapter.query_service
        expect(query_service.find_by(id: accession.id).date).to eq(["2001-01-01"])
      end
    end

    context "when an accession has a UTC-formatted date" do
      it "updates date to use YYYY-MM-DD format" do
        accession = FactoryBot.create_for_repository(:numismatic_accession, date: DateTime.strptime("01/01/2001", "%m/%d/%Y"))
        described_class.call
        query_service = Valkyrie.config.metadata_adapter.query_service
        expect(query_service.find_by(id: accession.id).date).to eq(["2001-01-01"])
      end
    end

    context "when an accession has a MM/DD/YYYY formatted date" do
      it "updates date to use YYYY-MM-DD format" do
        accession = FactoryBot.create_for_repository(:numismatic_accession, date: "01/01/2001")
        described_class.call
        query_service = Valkyrie.config.metadata_adapter.query_service
        expect(query_service.find_by(id: accession.id).date).to eq(["2001-01-01"])
      end
    end

    context "when an accession has an invalid date" do
      it "sets accession date to nil" do
        accession = FactoryBot.create_for_repository(:numismatic_accession, date: "notadate")
        described_class.call
        query_service = Valkyrie.config.metadata_adapter.query_service
        expect(query_service.find_by(id: accession.id).date).to be_nil
      end
    end

    # context "when a map is restricted" do
    #   it "updates the rights statement to be \"in copyright\"" do
    #     stub_ezid
    #     scanned_map = FactoryBot.create_for_repository(:complete_campus_only_scanned_map)
    #     raster_map = FactoryBot.create_for_repository(:complete_campus_only_raster_resource)
    #     vector_map = FactoryBot.create_for_repository(:complete_campus_only_vector_resource)
    #     private_scanned_map = FactoryBot.create_for_repository(:complete_private_scanned_map)
    #     open_scanned_map = FactoryBot.create_for_repository(:complete_open_scanned_resource)

    # described_class.call

    #     query_service = Valkyrie.config.metadata_adapter.query_service
    #     expect(query_service.find_by(id: scanned_map.id).rights_statement).to eq [RightsStatements.in_copyright]
    #     expect(query_service.find_by(id: raster_map.id).rights_statement).to eq [RightsStatements.in_copyright]
    #     expect(query_service.find_by(id: vector_map.id).rights_statement).to eq [RightsStatements.in_copyright]
    #     expect(query_service.find_by(id: private_scanned_map.id).rights_statement).to eq [RightsStatements.in_copyright]
    #     expect(query_service.find_by(id: open_scanned_map.id).rights_statement).to eq [RightsStatements.no_known_copyright]
    #   end
    # end
  end
end
