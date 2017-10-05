# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LinkedData::LinkedEphemeraTerm do
  subject(:linked_ephemera_term) { described_class.new(resource: ephemera_term) }
  let(:ephemera_vocabulary) { FactoryGirl.create_for_repository(:ephemera_vocabulary) }
  let(:ephemera_term) { FactoryGirl.create_for_repository(:ephemera_term, member_of_vocabulary_id: [ephemera_vocabulary.id]) }

  describe '#local_fields' do
    it 'exposes the attributes for serialization into JSON-LD' do
      expect(linked_ephemera_term.local_fields).not_to be_empty
      expect(linked_ephemera_term.local_fields[:'@id']).to be_a URI
      expect(linked_ephemera_term.local_fields[:'@id'].to_s).to eq "https://plum.princeton.edu/ns/testVocabulary/testTerm"
      expect(linked_ephemera_term.local_fields[:'@type']).to eq "skos:Concept"
      expect(linked_ephemera_term.local_fields[:pref_label]).to eq "test term"
      expect(linked_ephemera_term.local_fields[:in_scheme]).to be_a Hash
      expect(linked_ephemera_term.local_fields[:in_scheme]).to include(pref_label: 'test vocabulary')
    end
  end
end
