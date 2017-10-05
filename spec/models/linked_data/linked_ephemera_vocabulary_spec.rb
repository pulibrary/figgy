# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LinkedData::LinkedEphemeraVocabulary do
  subject(:linked_ephemera_vocabulary) { described_class.new(resource: ephemera_vocabulary) }
  let(:ephemera_vocabulary) { FactoryGirl.create_for_repository(:ephemera_vocabulary) }

  describe '#local_fields' do
    it 'exposes the attributes for serialization into JSON-LD' do
      expect(linked_ephemera_vocabulary.local_fields).not_to be_empty
      expect(linked_ephemera_vocabulary.local_fields[:'@id']).to be_a URI
      expect(linked_ephemera_vocabulary.local_fields[:'@id'].to_s).to eq "https://plum.princeton.edu/ns/testVocabulary"
      expect(linked_ephemera_vocabulary.local_fields[:'@type']).to eq "skos:ConceptScheme"
      expect(linked_ephemera_vocabulary.local_fields[:pref_label]).to eq "test vocabulary"
    end

    context 'with an external URI' do
      let(:ephemera_vocabulary) { FactoryGirl.create_for_repository(:ephemera_vocabulary, uri: 'https://namespace.org/ns/anotherVocabulary/anotherTerm') }

      it 'uses a SKOS:exactMatch predicate to link the two resources' do
        expect(linked_ephemera_vocabulary.local_fields[:exact_match]).to eq "https://namespace.org/ns/anotherVocabulary/anotherTerm"
      end
    end
  end
end
