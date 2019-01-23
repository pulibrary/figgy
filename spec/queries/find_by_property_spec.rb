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

    context "when no objects have the string in that property" do
      it "returns no results" do
        output = query.find_by_property(property: :barcode, value: "notabarcode")
        expect(output.to_a).to be_empty
      end
    end
  end
end
