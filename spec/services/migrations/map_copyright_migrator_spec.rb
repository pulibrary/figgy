# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::MapCopyrightMigrator do
  describe ".call" do
    context "when a map is restricted" do
      it "updates the rights statement to be \"in copyright\"" do
        stub_ezid
        scanned_map = FactoryBot.create_for_repository(:complete_campus_only_scanned_map)
        raster_map = FactoryBot.create_for_repository(:complete_campus_only_raster_resource)
        vector_map = FactoryBot.create_for_repository(:complete_campus_only_vector_resource)
        private_scanned_map = FactoryBot.create_for_repository(:complete_private_scanned_map)
        open_scanned_map = FactoryBot.create_for_repository(:complete_open_scanned_resource)

        described_class.call

        query_service = Valkyrie.config.metadata_adapter.query_service
        expect(query_service.find_by(id: scanned_map.id).rights_statement).to eq [RightsStatements.in_copyright]
        expect(query_service.find_by(id: raster_map.id).rights_statement).to eq [RightsStatements.in_copyright]
        expect(query_service.find_by(id: vector_map.id).rights_statement).to eq [RightsStatements.in_copyright]
        expect(query_service.find_by(id: private_scanned_map.id).rights_statement).to eq [RightsStatements.in_copyright]
        expect(query_service.find_by(id: open_scanned_map.id).rights_statement).to eq [RightsStatements.no_known_copyright]
      end
    end
  end
end
