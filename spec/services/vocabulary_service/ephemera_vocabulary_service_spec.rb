# frozen_string_literal: true
require "rails_helper"

RSpec.describe VocabularyService::EphemeraVocabularyService do
  subject(:service) do
    described_class.new(change_set_persister: change_set_persister,
                        persist_if_not_found: true)
  end
  let(:change_set_persister) do
    ChangeSetPersister.new(
      metadata_adapter: adapter,
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { adapter.query_service }

  before do
    politics_and_government = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                               label: "Politics and government")

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Government policy",
                                     member_of_vocabulary_id: politics_and_government.id)

    imported_terms = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                      label: "Imported Terms")

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Some place",
                                     member_of_vocabulary_id: imported_terms.id)

    languages = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                 label: "LAE Languages")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Spanish"],
                                     code: ["es"],
                                     member_of_vocabulary_id: languages.id)

    areas = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                             label: "LAE Areas")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Chile"],
                                     member_of_vocabulary_id: areas.id)
  end

  it "can find an existing subject" do
    subject = service.find_subject_by(category: "Politics and government",
                                      topic: "Government policy")
    expect(subject.label.first).to eq("Government policy")
  end

  it "can find a new subject" do
    subject = service.find_subject_by(category: "Politics and government",
                                      topic: "Bogus topic")
    expect(subject).not_to be_nil
    expect(subject.label.first).to eq("Bogus topic")
  end

  it "can recover from being given a bad category" do
    subject = service.find_subject_by(category: "Bogus category",
                                      topic: "Bogus topic")
    expect(subject).not_to be_nil
    expect(subject.label.first).to eq("Bogus topic")
  end

  it "can find a vocabulary" do
    vocab = service.find_vocabulary_by(label: "LAE Languages")
    expect(vocab.label.first).to eq("LAE Languages")
  end

  it "can find an imported vocabulary" do
    expect(service.imported_vocabulary.label.first).to eq("Imported Terms")
  end

  it "can find terms" do
    term = service.find_term(code: "es")
    expect(term).to be_a(Valkyrie::ID)

    term = service.find_term(label: "Chile")
    expect(term).to be_a(Valkyrie::ID)
  end

  context "when persist_if_not_found is false" do
    before do
      service.persist_if_not_found = false
    end

    it "cannot find a new term" do
      term = service.find_term(label: "English")
      expect(term).to be_nil
    end

    it "cannot find a new vocabulary" do
      vocab = service.find_vocabulary_by(label: "Made up vocab")
      expect(vocab).to be_nil
    end
  end

  context "when persist_if_not_found is true" do
    before do
      service.persist_if_not_found = true
    end

    it "can find a new term" do
      term = service.find_term(label: "English")
      expect(term).to be_an(EphemeraTerm)
      expect(term.label.first).to eq("English")
    end

    it "can find a new vocabulary" do
      vocab = service.find_vocabulary_by(label: "Made up vocab")
      expect(vocab.label.first).to eq("Made up vocab")
    end
  end
end
