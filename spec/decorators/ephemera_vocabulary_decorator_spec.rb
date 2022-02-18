# frozen_string_literal: true

require "rails_helper"

RSpec.describe EphemeraVocabularyDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:ephemera_vocabulary) }
  describe "decoration" do
    it "decorates an EphemeraVocabulary" do
      expect(resource.decorate).to be_a described_class
    end
  end
  it "does not manage files" do
    expect(decorator.manageable_files?).to be false
  end
  it "does not order files" do
    expect(decorator.orderable_files?).to be false
  end
  it "does not manage structures" do
    expect(decorator.manageable_structure?).to be false
  end
  it "exposes the label as the title" do
    expect(resource.decorate.title).to eq resource.decorate.label
  end
  context "when a child of another vocabulary" do
    let(:vocab) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "test parent vocabulary") }
    let(:resource) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryBot.build(:ephemera_vocabulary)
      res.member_of_vocabulary_id = vocab.id
      adapter.persister.save(resource: res)
    end

    it "retrieves the parent vocabulary" do
      expect(resource.decorate.vocabulary).to be_a EphemeraVocabulary
      expect(resource.decorate.vocabulary.label).to eq "test parent vocabulary"
    end

    it "exposes the label for the vocabulary" do
      expect(resource.decorate.vocabulary_label).to eq resource.decorate.vocabulary.label
    end

    it "features the URI of the vocabulary in the internal URL" do
      expect(resource.decorate.internal_url).to be_a URI
      expect(resource.decorate.internal_url.to_s).to eq "https://figgy.princeton.edu/ns/testParentVocabulary/testVocabulary"
    end
  end

  describe "#terms" do
    it "lists all terms in alphabetical order" do
      resource = FactoryBot.create_for_repository(:ephemera_vocabulary)
      FactoryBot.create_for_repository(:ephemera_term, label: "C", member_of_vocabulary_id: resource.id)
      FactoryBot.create_for_repository(:ephemera_term, label: "A", member_of_vocabulary_id: resource.id)

      expect(resource.decorate.terms.map(&:label)).to eq ["A", "C"]
    end
  end

  context "when a parent of other vocabularies" do
    let(:resource) { FactoryBot.create_for_repository(:ephemera_vocabulary) }
    before do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      child1 = FactoryBot.build(:ephemera_vocabulary, label: "test child vocabulary2")
      child1.member_of_vocabulary_id = resource.id
      adapter.persister.save(resource: child1)
      child2 = FactoryBot.build(:ephemera_vocabulary, label: "test child vocabulary1")
      child2.member_of_vocabulary_id = resource.id
      adapter.persister.save(resource: child2)
    end

    it "retrieves the parent vocabulary" do
      categories = resource.decorate.categories
      expect(categories.length).to eq 2
      expect(categories.map(&:label)).to eq ["test child vocabulary1", "test child vocabulary2"]
      expect(categories.first).to be_a EphemeraVocabulary
      expect(categories.last).to be_a EphemeraVocabulary
    end
  end
end
