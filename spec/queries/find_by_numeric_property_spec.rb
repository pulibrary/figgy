# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindByNumericProperty do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:accession) { FactoryBot.create_for_repository(:numismatic_accession, accession_number: 123) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_by_numeric_property" do
    it "can find objects with numbers in it by a property" do
      output = query.find_by_numeric_property(property: :accession_number, value: accession.accession_number).first
      expect(output.id).to eq accession.id
    end

    context "when no objects have the number in that property" do
      it "returns no results" do
        output = query.find_by_numeric_property(property: :accession_number, value: 999)
        expect(output.to_a).to be_empty
      end
    end
  end
end
