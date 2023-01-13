# frozen_string_literal: true
require "rails_helper"

RSpec.describe EventGenerator::GeoblacklightEventGenerator do
  subject(:event_generator) { described_class.new(rabbit_connection) }
  let(:rabbit_connection) { instance_double(GeoblacklightMessagingClient, publish: true) }
  let(:coverage) { GeoCoverage.new(43.039, -69.856, 42.943, -71.032).to_s }
  let(:record) { FactoryBot.create_for_repository(:complete_scanned_map, coverage: coverage) }

  it_behaves_like "an EventGenerator"

  describe "#record_deleted" do
    it "publishes a persistent JSON delete message with the geoblacklight slug as the id" do
      slug = GeoDiscovery::DocumentBuilder::SlugBuilder.new(record).slug
      expected_result = {
        "id" => slug,
        "event" => "DELETED",
        "bulk" => "false"
      }

      event_generator.record_deleted(record)

      expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
    end
  end

  describe "#record_updated" do
    context "with a record in a completed state" do
      it "publishes a persistent JSON updated message with geoblacklight document" do
        gbl_doc = GeoDiscovery::DocumentBuilder.new(record, GeoDiscovery::GeoblacklightDocument.new)
        expected_result = {
          "id" => record.id.to_s,
          "event" => "UPDATED",
          "bulk" => "false",
          "doc" => gbl_doc
        }

        event_generator.record_updated(record)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end
    context "with a record updated as part of a bulk  operation" do
      before do
        allow(ENV).to receive(:[]).with("BULK").and_return("true")
      end

      it "publishes a persistent JSON updated message with a bulk flag set to true" do
        gbl_doc = GeoDiscovery::DocumentBuilder.new(record, GeoDiscovery::GeoblacklightDocument.new)
        expected_result = {
          "id" => record.id.to_s,
          "event" => "UPDATED",
          "bulk" => "true",
          "doc" => gbl_doc
        }

        event_generator.record_updated(record)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end
    context "with a record in a takedown state" do
      let(:record) { FactoryBot.create_for_repository(:scanned_map, state: "takedown") }

      it "publishes a persistent JSON delete message with the geoblacklight slug as the id" do
        slug = GeoDiscovery::DocumentBuilder::SlugBuilder.new(record).slug
        expected_result = {
          "id" => slug,
          "event" => "DELETED",
          "bulk" => "false"
        }

        event_generator.record_updated(record)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end

    context "with a record in a pending state" do
      let(:record) { FactoryBot.create_for_repository(:scanned_map, state: "pending") }

      it "does not publish a JSON message" do
        event_generator.record_updated(record)

        expect(rabbit_connection).not_to have_received(:publish)
      end
    end
  end

  describe "#record_member_updated" do
    context "with a record in a completed state" do
      it "publishes a persistent JSON updated message with geoblacklight document" do
        gbl_doc = GeoDiscovery::DocumentBuilder.new(record, GeoDiscovery::GeoblacklightDocument.new)
        expected_result = {
          "id" => record.id.to_s,
          "event" => "UPDATED",
          "bulk" => "false",
          "doc" => gbl_doc
        }

        event_generator.record_member_updated(record)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end

    context "with a record in a takedown state" do
      let(:record) { FactoryBot.create_for_repository(:scanned_map, state: "takedown") }

      it "publishes a persistent JSON delete message with the geoblacklight slug as the id" do
        slug = GeoDiscovery::DocumentBuilder::SlugBuilder.new(record).slug
        expected_result = {
          "id" => slug,
          "event" => "DELETED",
          "bulk" => "false"
        }

        event_generator.record_member_updated(record)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end

    context "with a record in a pending state" do
      let(:record) { FactoryBot.create_for_repository(:scanned_map, state: "pending") }

      it "does not publish a JSON message" do
        event_generator.record_member_updated(record)

        expect(rabbit_connection).not_to have_received(:publish)
      end
    end
  end

  describe "#valid?" do
    context "with a fileset" do
      let(:record) { FactoryBot.create_for_repository(:file_set) }

      it "is not valid" do
        expect(event_generator.valid?(record)).to be false
      end
    end

    context "with a scanned resource" do
      let(:record) { FactoryBot.create_for_repository(:scanned_resource) }

      it "is not valid" do
        expect(event_generator.valid?(record)).to be false
      end
    end

    context "when a record generates an invalid geoblacklight document" do
      let(:coverage) { nil }

      it "is not valid" do
        expect(event_generator.valid?(record)).to be false
      end
    end

    context "when a record generates an invalid geoblacklight document" do
      let(:document_builder) { instance_double(GeoDiscovery::DocumentBuilder) }
      before do
        allow(GeoDiscovery::DocumentBuilder).to receive(:new).and_return(document_builder)
        allow(document_builder).to receive(:to_hash).and_raise(StandardError)
      end

      it "still emits a valid event" do
        expect(event_generator.valid?(record)).to be true
      end
    end
  end
end
