# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IngestVocabService do
  let(:genre_csv) { Rails.root.join('spec', 'fixtures', 'lae_genres.csv') }
  let(:subject_csv) { Rails.root.join('spec', 'fixtures', 'lae_subjects.csv') }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:lae_storage) }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }

  let(:ephemera_vocabularies) { QueryAdapter::CompositeQueryAdapter::EphemeraVocabularyCompositeQueryAdapter.new(query_service: adapter.query_service, change_set_persister: change_set_persister) }
  let(:ephemera_terms) { QueryAdapter::CompositeQueryAdapter::EphemeraTermCompositeQueryAdapter.new(query_service: adapter.query_service, change_set_persister: change_set_persister) }

  describe "#ingest" do
    context "with categories" do
      let(:ingest_vocab_service) { described_class.new(change_set_persister, subject_csv, nil, label: 'subject', category: 'category', uri: 'uri') }
      before do
        ingest_vocab_service.ingest
      end

      it "loads the terms with categories" do
        expect(ephemera_terms.all.map(&:label)).to contain_exactly('Agricultural development projects', 'Architecture')
        expect(ephemera_vocabularies.all.map(&:label)).to contain_exactly('Agrarian and rural issues', 'Arts and culture')
      end
    end

    context "with categories & a parent vocab name" do
      let(:ingest_vocab_service) { described_class.new(change_set_persister, subject_csv, "LAE Subjects", label: 'subject', category: 'category', uri: 'uri') }
      before do
        ingest_vocab_service.ingest
      end

      it "loads the terms with categories & a parent vocab" do
        expect(ephemera_terms.all.map(&:label)).to contain_exactly('Agricultural development projects', 'Architecture')
        expect(ephemera_vocabularies.all.map(&:label)).to contain_exactly('LAE Subjects', 'Agrarian and rural issues', 'Arts and culture')
        expect(ephemera_vocabularies.find_by(label: "Arts and culture").vocabulary.label).to eq 'LAE Subjects'
      end
    end

    context "without categories" do
      let(:ingest_vocab_service) { described_class.new(change_set_persister, genre_csv, "Genres", label: 'pul_label', tgm_label: 'tgm_label', lcsh_label: 'lcsh_label', uri: 'uri') }
      before do
        ingest_vocab_service.ingest
      end

      it "loads the terms with categories" do
        expect(ephemera_terms.all.map(&:label)).to contain_exactly('Brochures', 'Electoral paraphernalia')
        expect(ephemera_terms.all.map(&:lcsh_label)).to include('Political collectibles')
        expect(ephemera_terms.all.map(&:tgm_label)).to include('Leaflets')
      end
    end
  end
end
