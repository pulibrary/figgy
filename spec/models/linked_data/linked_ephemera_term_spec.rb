# frozen_string_literal: true

require "rails_helper"

RSpec.describe LinkedData::LinkedEphemeraTerm do
  subject(:linked_ephemera_term) { described_class.new(resource: resource) }
  let(:ephemera_vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary) }
  let(:resource) { FactoryBot.create_for_repository(:ephemera_term, member_of_vocabulary_id: [ephemera_vocabulary.id]) }

  it_behaves_like "LinkedData::Resource"

  describe "#as_jsonld" do
    it "exposes the attributes for serialization into JSON-LD" do
      expect(linked_ephemera_term.as_jsonld).not_to be_empty
      expect(linked_ephemera_term.as_jsonld["@id"].to_s).to eq "http://www.example.com/catalog/#{resource.id}"
      expect(linked_ephemera_term.as_jsonld["@type"]).to eq "skos:Concept"
      expect(linked_ephemera_term.as_jsonld["pref_label"]).to eq "test term"
      expect(linked_ephemera_term.as_jsonld["in_scheme"]).to be_a Hash
      expect(linked_ephemera_term.as_jsonld["in_scheme"]).to include("pref_label" => "test vocabulary")
    end
  end
end
