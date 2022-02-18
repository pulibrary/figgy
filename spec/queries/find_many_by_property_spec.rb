# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindManyByProperty do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:box) { FactoryBot.create_for_repository(:ephemera_folder, barcode: "1234567") }
  let(:box2) { FactoryBot.create_for_repository(:ephemera_folder, barcode: "2345678") }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_many_by_property" do
    it "can find objects with strings in it by a property" do
      output = query.find_many_by_property(property: :barcode, values: [box.barcode.first, box2.barcode.first])
      expect(output.length).to eq 2
      output_ids = output.map(&:id)
      expect(output_ids).to include box.id
      expect(output_ids).to include box2.id
    end

    context "when no objects have the string in that property" do
      it "returns no results" do
        output = query.find_many_by_property(property: :barcode, values: ["notabarcode"])
        expect(output.to_a).to be_empty
      end
    end
  end
end
