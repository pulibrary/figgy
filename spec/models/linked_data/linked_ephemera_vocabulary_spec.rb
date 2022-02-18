# frozen_string_literal: true

require "rails_helper"

RSpec.describe LinkedData::LinkedEphemeraVocabulary do
  subject(:linked_ephemera_vocabulary) { described_class.new(resource: resource) }
  let(:resource) { FactoryBot.create_for_repository(:ephemera_vocabulary) }

  it_behaves_like "LinkedData::Resource"

  describe "#as_jsonld" do
    it "exposes the attributes for serialization into JSON-LD" do
      expect(linked_ephemera_vocabulary.as_jsonld).not_to be_empty
      expect(linked_ephemera_vocabulary.as_jsonld["@id"].to_s).to eq "https://figgy.princeton.edu/ns/testVocabulary"
      expect(linked_ephemera_vocabulary.as_jsonld["@type"]).to eq "skos:ConceptScheme"
      expect(linked_ephemera_vocabulary.as_jsonld["pref_label"]).to eq "test vocabulary"
    end

    context "with an external URI" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_vocabulary, uri: "https://namespace.org/ns/anotherVocabulary/anotherTerm") }

      it "uses a SKOS:exactMatch predicate to link the two resources" do
        expect(linked_ephemera_vocabulary.as_jsonld["exact_match"]).to eq "@id" => "https://namespace.org/ns/anotherVocabulary/anotherTerm"
      end
    end
  end
end
