# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestVocabService do
  let(:genre_csv) { Rails.root.join("spec", "fixtures", "lae_genres.csv") }
  let(:subject_csv) { Rails.root.join("spec", "fixtures", "lae_subjects.csv") }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { adapter.query_service }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }

  let(:ephemera_vocabularies) { query_service.find_all_of_model(model: EphemeraVocabulary).to_a.map(&:decorate) }
  let(:ephemera_vocabulary_query) { FindEphemeraVocabularyByLabel.new(query_service: query_service) }
  let(:ephemera_terms) { query_service.find_all_of_model(model: EphemeraTerm).to_a.map(&:decorate) }
  let(:logger) { instance_double("Logger") }

  before do
    allow(logger).to receive(:info).and_return(nil)
  end

  describe "#ingest" do
    context "with categories" do
      let(:ingest_vocab_service) { described_class.new(change_set_persister, subject_csv, "Subjects", { label: "subject", category: "category", uri: "uri" }, logger) }
      before do
        ingest_vocab_service.ingest
      end

      it "loads the terms with categories" do
        expect(ephemera_terms.map(&:label)).to contain_exactly("Agricultural development projects", "Architecture")
        expect(ephemera_terms[0].uri.to_s).to eq "http://id.loc.gov/authorities/subjects/sh85002306"
        expect(ephemera_vocabularies.map(&:label)).to contain_exactly("Agrarian and rural issues", "Arts and culture", "Subjects")
      end
    end

    context "with categories & a parent vocab name" do
      let(:ingest_vocab_service) { described_class.new(change_set_persister, subject_csv, "LAE Subjects", { label: "subject", category: "category", uri: "uri" }, logger) }
      before do
        ingest_vocab_service.ingest
      end

      it "loads the terms with categories & a parent vocab" do
        expect(ephemera_terms.map(&:label)).to contain_exactly("Agricultural development projects", "Architecture")
        expect(ephemera_vocabularies.map(&:label)).to contain_exactly("LAE Subjects", "Agrarian and rural issues", "Arts and culture")
        expect(ephemera_vocabulary_query.find_ephemera_vocabulary_by_label(label: "Arts and culture").decorate.vocabulary.label).to eq "LAE Subjects"
      end
    end

    context "without categories" do
      let(:ingest_vocab_service) { described_class.new(change_set_persister, genre_csv, "Genres", { label: "pul_label", tgm_label: "tgm_label", lcsh_label: "lcsh_label", uri: "uri" }, logger) }
      before do
        ingest_vocab_service.ingest
      end

      it "loads the terms with categories" do
        expect(ephemera_terms.flat_map(&:label)).to contain_exactly("Brochures", "Electoral paraphernalia")
        expect(ephemera_terms.flat_map(&:lcsh_label)).to include("Political collectibles")
        expect(ephemera_terms.flat_map(&:tgm_label)).to include("Leaflets")
      end
    end
  end
end
