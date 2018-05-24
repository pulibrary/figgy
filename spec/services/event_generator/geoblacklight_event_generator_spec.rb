# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe EventGenerator::GeoblacklightEventGenerator do
  subject(:event_generator) { described_class.new(rabbit_connection) }
  let(:rabbit_connection) { instance_double(GeoblacklightMessagingClient, publish: true) }
  let(:record) { FactoryBot.create_for_repository(:complete_scanned_map) }

  it_behaves_like "an EventGenerator"

  describe "#record_deleted" do
    it "publishes a persistent JSON delete message with the geoblacklight slug as the id" do
      slug = GeoDiscovery::DocumentBuilder::SlugBuilder.new(record).slug
      expected_result = {
        "id" => slug,
        "event" => "DELETED"
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
          "event" => "DELETED"
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
          "event" => "MEMBER_UPDATED",
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
          "event" => "DELETED"
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
  end
end
