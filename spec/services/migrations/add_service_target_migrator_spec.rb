# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::AddServiceTargetMigrator do
  describe ".call" do
    context "when given raster resources without a service target with a single file set" do
      it "adds the service target tiles" do
        raster_fileset = FactoryBot.create_for_repository(:geo_raster_file_set)
        FactoryBot.create_for_repository(:raster_resource, member_ids: raster_fileset.id)

        described_class.call

        query_service = Valkyrie.config.metadata_adapter.query_service
        raster_resource = query_service.find_all_of_model(model: RasterResource).first
        expect(Wayfinder.for(raster_resource).file_sets.first.service_targets).to eq ["tiles"]
        expect(CreateDerivativesJob).to have_been_enqueued.once.with(raster_fileset.id.to_s)
      end
    end

    context "when given a raster resource without a service target and an fgdc file" do
      it "adds the service target tiles" do
        raster_fileset = FactoryBot.create_for_repository(:geo_raster_file_set)
        fgdc_fileset = FactoryBot.create_for_repository(:geo_metadata_file_set)
        FactoryBot.create_for_repository(:raster_resource, member_ids: [raster_fileset.id, fgdc_fileset.id])

        described_class.call
        query_service = Valkyrie.config.metadata_adapter.query_service
        raster_resource = query_service.find_all_of_model(model: RasterResource).first
        expect(Wayfinder.for(raster_resource).file_sets.first.service_targets).to eq ["tiles"]
        expect(CreateDerivativesJob).to have_been_enqueued.once.with(raster_fileset.id.to_s)
      end
    end
  end
end
