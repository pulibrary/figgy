# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventGenerator::OrangelightEventGenerator do
  subject(:event_generator) { described_class.new(rabbit_connection) }
  let(:rabbit_connection) { instance_double(OrangelightMessagingClient, publish: true) }
  let(:parent_issue) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: [record.id]) }
  let(:record) { FactoryBot.create_for_repository(:coin, state: "complete") }

  it_behaves_like "an EventGenerator"

  before do
    record
    parent_issue
  end

  describe "#record_deleted" do
    it "publishes a persistent JSON delete message with the orangelight id as the id" do
      expected_result = {
        "id" => record.decorate.orangelight_id,
        "event" => "DELETED",
        "bulk" => "false"
      }

      event_generator.record_deleted(record)

      expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
    end
  end

  describe "#record_updated" do
    context "with a record in a completed state" do
      it "publishes a persistent JSON updated message with an orangelight document" do
        orangelight_doc = OrangelightDocument.new(record).to_h
        expected_result = {
          "id" => record.id.to_s,
          "event" => "UPDATED",
          "bulk" => "false",
          "doc" => orangelight_doc
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
        orangelight_doc = OrangelightDocument.new(record).to_h
        expected_result = {
          "id" => record.id.to_s,
          "event" => "UPDATED",
          "bulk" => "true",
          "doc" => orangelight_doc
        }

        event_generator.record_updated(record)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end

    context "with a record in a draft state" do
      let(:record) { FactoryBot.create_for_repository(:coin, state: "draft") }

      it "publishes a JSON delete message" do
        expected_result = {
          "id" => record.decorate.orangelight_id,
          "event" => "DELETED",
          "bulk" => "false"
        }
        event_generator.record_updated(record)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end
  end

  describe "#record_member_updated" do
    context "with a record in a completed state" do
      it "publishes a persistent JSON updated message with an orangelight document" do
        orangelight_doc = OrangelightDocument.new(record).to_h
        expected_result = {
          "id" => record.id.to_s,
          "event" => "UPDATED",
          "bulk" => "false",
          "doc" => orangelight_doc
        }

        event_generator.record_member_updated(record)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end

    context "with a record in a draft state" do
      let(:record) { FactoryBot.create_for_repository(:coin, state: "draft") }

      it "publishes a JSON delete message" do
        expected_result = {
          "id" => record.decorate.orangelight_id,
          "event" => "DELETED",
          "bulk" => "false"
        }
        event_generator.record_member_updated(record)

        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end
  end

  describe "#valid?" do
    context "with a coin and a parent issue" do
      let(:parent_issue) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: [record.id]) }
      let(:record) { FactoryBot.create_for_repository(:coin) }

      it "is valid" do
        expect(event_generator.valid?(record)).to be true
      end
    end

    context "with a coin and no parent issue" do
      let(:parent_issue) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: []) }
      let(:record) { FactoryBot.create_for_repository(:coin) }

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
