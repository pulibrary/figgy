# frozen_string_literal: true
require "rails_helper"

RSpec.describe GeoserverPublishService do
  with_queue_adapter :inline

  subject(:service) { described_class.new(resource: file_set) }
  let(:resource_title) { "Test Title" }
  let(:file_set) { query_service.find_members(resource: resource).to_a.first }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:event_generator) { instance_double(EventGenerator, derivatives_created: true) }
  let(:geoserver_derivatives_path) { Figgy.config["geoserver"]["derivatives_path"] }
  let(:shapefile_name) { "display_vector/p-#{file_set.id}.shp" }
  let(:file) { fixture_file_upload("files/vector/shapefile.zip", "application/zip") }
  let(:tika_output) { tika_shapefile_output }

  describe "#delete" do
    let(:resource) do
      FactoryBot.create_for_repository(
        :vector_resource,
        files: [file],
        title: RDF::Literal.new(resource_title, language: :en),
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      )
    end

    before do
      allow(Geoserver::Publish).to receive(:delete_shapefile)
    end

    it "calls method for deleting a shapefile on the GeoServer::Publish gem" do
      params = {
        id: "p-#{file_set.id}",
        workspace_name: Figgy.config["geoserver"]["open"]["workspace"]
      }
      service.delete

      expect(Geoserver::Publish).to have_received(:delete_shapefile).with(params)
    end
  end

  describe "#create" do
    let(:resource) do
      FactoryBot.create_for_repository(
        :vector_resource,
        files: [file],
        title: RDF::Literal.new(resource_title, language: :en),
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      )
    end

    before do
      allow(Geoserver::Publish).to receive(:shapefile)
    end

    it "calls method for creating a shapefile on the GeoServer::Publish gem" do
      params = {
        id: "p-#{file_set.id}",
        workspace_name: Figgy.config["geoserver"]["authenticated"]["workspace"],
        title: resource_title
      }
      service.create

      expect(Geoserver::Publish).to have_received(:shapefile).with(hash_including(params))
    end
  end

  describe "#update" do
    let(:resource) do
      FactoryBot.create_for_repository(
        :vector_resource,
        files: [file],
        title: RDF::Literal.new(resource_title, language: :en),
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      )
    end

    before do
      allow(Geoserver::Publish).to receive(:delete_shapefile)
      allow(Geoserver::Publish).to receive(:shapefile)
    end

    it "calls delete on both public and authenticated workspaces and creates new layer" do
      service.update

      expect(Geoserver::Publish).to have_received(:delete_shapefile).with(hash_including(workspace_name: Figgy.config["geoserver"]["authenticated"]["workspace"]))
      expect(Geoserver::Publish).to have_received(:delete_shapefile).with(hash_including(workspace_name: Figgy.config["geoserver"]["open"]["workspace"]))
      expect(Geoserver::Publish).to have_received(:shapefile)
    end

    context "when there is an error deleting a layer" do
      let(:logger) { Logger.new(STDOUT) }

      before do
        allow(Geoserver::Publish).to receive(:delete_shapefile).and_raise(StandardError, "delete error")
        allow(Geoserver::Publish).to receive(:shapefile)
        allow(logger).to receive(:info)
      end

      it "logs the error and continues to create the layer" do
        described_class.new(resource: file_set, logger: logger).update

        expect(logger).to have_received(:info).twice.with("delete error")
        expect(Geoserver::Publish).to have_received(:shapefile)
      end
    end
  end
end
