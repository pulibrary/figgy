# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventGenerator::GeoserverEventGenerator do
  with_queue_adapter :inline

  subject(:event_generator) { described_class.new(rabbit_connection) }
  let(:rabbit_connection) { instance_double(GeoblacklightMessagingClient, publish: true) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:file) { fixture_file_upload("files/vector/shapefile.zip", "application/zip") }
  let(:tika_output) { tika_shapefile_output }
  let(:resource) { FactoryBot.create_for_repository(:vector_resource, files: [file]) }
  let(:record) { query_service.find_members(resource: resource).to_a.first }

  it_behaves_like "an EventGenerator"

  describe "#derivatives_created" do
    it "publishes a persistent JSON message" do
      event_generator.derivatives_created(record)
      expect(rabbit_connection).to have_received(:publish)
    end
  end

  describe "#derivatives_deleted" do
    it "publishes two persistent JSON messages, one for each workspace" do
      event_generator.derivatives_deleted(record)
      expect(rabbit_connection).to have_received(:publish).twice
    end
  end

  describe "#record_updated" do
    it "publishes a persistent JSON message" do
      event_generator.record_updated(resource)
      expect(rabbit_connection).to have_received(:publish)
    end
  end

  describe "#valid?" do
    context "with a raster file set with a derivative" do
      let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tif") }
      let(:tika_output) { tika_geotiff_output }
      let(:resource) { FactoryBot.create_for_repository(:raster_resource, files: [file]) }

      it "publishes a persistent JSON message" do
        expect(event_generator.valid?(record)).to be true
      end
    end

    context "with a geo resource" do
      let(:record) { FactoryBot.create_for_repository(:vector_resource) }

      it "is valid" do
        expect(event_generator.valid?(record)).to be true
      end
    end

    context "with a scanned resource" do
      let(:record) { FactoryBot.create_for_repository(:scanned_resource) }

      it "is not valid" do
        expect(event_generator.valid?(record)).to be false
      end
    end

    context "with a scanned map" do
      let(:record) { FactoryBot.create_for_repository(:scanned_map) }

      it "is not valid" do
        expect(event_generator.valid?(record)).to be false
      end
    end

    context "with a file set without a derivative" do
      before do
        persister = Valkyrie.config.metadata_adapter.persister
        record.file_metadata = record.file_metadata.reject(&:derivative?)
        persister.save(resource: record)
      end

      it "is not valid" do
        expect(event_generator.valid?(record)).to be false
      end
    end
  end
end
