# frozen_string_literal: true
require "rails_helper"

describe GeoserverPublishJob do
  with_queue_adapter :inline

  let(:publish_service) { instance_double(GeoserverPublishService) }
  let(:tika_output) { tika_shapefile_output }

  before do
    stub_ezid
    allow(publish_service).to receive(:delete)
    allow(GeoserverPublishService).to receive(:new).and_return(publish_service)
  end

  describe "#perform" do
    context "when deleting vector resource" do
      before do
        allow(publish_service).to receive(:create)
      end

      it "calls the delete method on GeoserverPublishService" do
        file = fixture_file_upload("files/vector/shapefile.zip", "application/zip")
        resource = FactoryBot.create_for_repository(:complete_open_vector_resource, files: [file])
        described_class.perform_now(operation: "delete", resource_id: resource.id.to_s)
        expect(publish_service).to have_received(:delete)
      end
    end

    context "when deleting derivatives" do
      before do
        allow(publish_service).to receive(:delete)
      end

      it "calls the delete method on GeoserverPublishService" do
        resource = FactoryBot.create_for_repository(:geo_vector_file_set)
        described_class.perform_now(operation: "derivatives_delete", resource_id: resource.id.to_s)
        expect(publish_service).to have_received(:delete)
      end
    end

    context "when creating derivatives" do
      before do
        allow(publish_service).to receive(:create)
      end

      it "calls the create method on GeoserverPublishService" do
        resource = FactoryBot.create_for_repository(:geo_vector_file_set)
        described_class.perform_now(operation: "derivatives_create", resource_id: resource.id.to_s)
        expect(publish_service).to have_received(:create)
      end
    end

    context "when updating the parent VectorResource" do
      before do
        allow(publish_service).to receive(:create)
        allow(publish_service).to receive(:update)
      end

      it "calls the update method on GeoserverPublishService" do
        file = fixture_file_upload("files/vector/shapefile.zip", "application/zip")
        resource = FactoryBot.create_for_repository(:complete_open_vector_resource, files: [file])
        described_class.perform_now(operation: "update", resource_id: resource.id.to_s)
        expect(publish_service).to have_received(:update)
      end
    end
  end
end
