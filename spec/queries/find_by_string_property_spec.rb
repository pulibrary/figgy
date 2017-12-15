# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FindByStringProperty do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:box) { FactoryBot.create_for_repository(:ephemera_folder, barcode: "1234567") }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_by_string_property" do
    it "can find objects with strings in it by a property" do
      output = query.find_by_string_property(property: :barcode, value: box.barcode.first).first
      expect(output.id).to eq box.id
    end
  end
end
