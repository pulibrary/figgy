# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindByProperty do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:box) { FactoryBot.create_for_repository(:ephemera_folder, barcode: "1234567") }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_by_property" do
    it "can find objects with strings in it by a property" do
      output = query.find_by_property(property: :barcode, value: box.barcode.first).first
      expect(output.id).to eq box.id
    end

    it "can find objects by metadata" do
      FactoryBot.create_for_repository(:scanned_resource, change_set: "test", title: "bla")
      FactoryBot.create_for_repository(:scanned_resource, change_set: "other", title: "bla")

      output = query.find_by_property(property: :metadata, value: { change_set: "test", title: "bla" })
      expect(output.to_a.length).to eq 1
    end

    it "can filter by model" do
      FactoryBot.create_for_repository(:scanned_resource, title: "test", contributor: "testing")
      FactoryBot.create_for_repository(:scanned_map, title: "test")

      output = query.find_by_property(property: :title, value: "test", model: ScannedResource)
      expect(output.to_a.length).to eq 1
      expect(output.first.contributor).to eq ["testing"]
    end

    it "can filter by created_at" do
      Timecop.travel(2021, 6, 30) do
        FactoryBot.create_for_repository(:scanned_resource, title: "test", contributor: "testing")
      end
      FactoryBot.create_for_repository(:scanned_resource, title: "test", contributor: "testing2")

      output = query.find_by_property(property: :title, value: "test", created_at: DateTime.new(2021, 3, 30)..DateTime.new(2021, 8, 30))
      expect(output.to_a.length).to eq 1
      expect(output.first.contributor).to eq ["testing"]
    end

    it "can return a lazy result set" do
      FactoryBot.create_for_repository(:scanned_resource, title: "test", contributor: "testing")
      FactoryBot.create_for_repository(:scanned_map, title: "test")

      allow(query_service.resource_factory).to receive(:to_resource).and_call_original
      output = query.find_by_property(property: :title, value: "test", lazy: true)
      output.first
      expect(query_service.resource_factory).to have_received(:to_resource).exactly(1).times
    end

    context "when no objects have the string in that property" do
      it "returns no results" do
        output = query.find_by_property(property: :barcode, value: "notabarcode")
        expect(output.to_a).to be_empty
      end
    end
  end
end
