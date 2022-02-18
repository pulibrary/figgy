# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventGenerator::ManifestEventGenerator do
  subject(:event_generator) { described_class.new(rabbit_connection) }
  let(:rabbit_connection) { instance_double(MessagingClient, publish: true) }
  let(:record) { FactoryBot.create_for_repository(:scanned_resource) }
  let(:collection) { FactoryBot.create_for_repository(:collection) }
  let(:record_in_collection) { FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id]) }

  it_behaves_like "an EventGenerator"

  describe "#record_created" do
    it "publishes a persistent JSON message" do
      expected_result = {
        "id" => record.id.to_s,
        "event" => "CREATED",
        "manifest_url" => "http://www.example.com/concern/scanned_resources/#{record.id}/manifest",
        "collection_slugs" => []
      }

      event_generator.record_created(record)

      expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
    end
    context "with a record in a collection" do
      it "embeds collection memberships" do
        expected_result = {
          "id" => record_in_collection.id.to_s,
          "event" => "CREATED",
          "manifest_url" => "http://www.example.com/concern/scanned_resources/#{record_in_collection.id}/manifest",
          "collection_slugs" => collection.slug
        }

        event_generator.record_created(record_in_collection)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end

    context "with a scanned map record in a collection" do
      let(:record_in_collection) { FactoryBot.create_for_repository(:scanned_map, member_of_collection_ids: [collection.id]) }
      it "embeds collection memberships" do
        expected_result = {
          "id" => record_in_collection.id.to_s,
          "event" => "CREATED",
          "manifest_url" => "http://www.example.com/concern/scanned_maps/#{record_in_collection.id}/manifest",
          "collection_slugs" => collection.slug
        }

        event_generator.record_created(record_in_collection)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end
  end

  describe "#record_deleted" do
    it "publishes a persistent JSON message" do
      expected_result = {
        "id" => record.id.to_s,
        "event" => "DELETED",
        "manifest_url" => "http://www.example.com/concern/scanned_resources/#{record.id}/manifest"
      }

      event_generator.record_deleted(record)

      expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
    end
  end

  describe "#record_updated" do
    context "with a record in a collection" do
      it "publishes a persistent JSON message with collection memberships" do
        expected_result = {
          "id" => record_in_collection.id.to_s,
          "event" => "UPDATED",
          "manifest_url" => "http://www.example.com/concern/scanned_resources/#{record_in_collection.id}/manifest",
          "collection_slugs" => collection.slug
        }

        event_generator.record_updated(record_in_collection)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end
  end

  describe "#valid?" do
    context "with a scanned map" do
      let(:record) { FactoryBot.create_for_repository(:scanned_map) }

      it "is valid" do
        expect(event_generator.valid?(record)).to be true
      end
    end
  end
end
