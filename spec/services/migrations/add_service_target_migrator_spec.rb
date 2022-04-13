# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::AddServiceTargetMigrator do
  describe ".call" do
    context "when given raster resources without a service target" do
      it "adds the service target tiles" do
        file_set = FactoryBot.create_for_repository(:file_set)
        FactoryBot.create_for_repository(:raster_resource, member_ids: file_set.id)

        described_class.call

        query_service = Valkyrie.config.metadata_adapter.query_service
        raster_resource = query_service.find_all_of_model(model: RasterResource).first
        expect(Wayfinder.for(raster_resource).file_sets.first.service_targets).to eq ["tiles"]
        expect(CreateDerivativesJob).to have_been_enqueued.once.with(file_set.id.to_s)
      end
    end
  end
end
