# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraVocabularyDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:ephemera_vocabulary) }
  describe "decoration" do
    it "decorates an EphemeraVocabulary" do
      expect(resource.decorate).to be_a described_class
    end
  end
  it 'does not manage files' do
    expect(decorator.manageable_files?).to be false
  end
  it 'does not manage structures' do
    expect(decorator.manageable_structure?).to be false
  end
  it 'exposes the metadata adapter' do
    expect(resource.decorate.metadata_adapter).to be_a Valkyrie::Persistence::Postgres::MetadataAdapter
  end
  it 'exposes the label as the title' do
    expect(resource.decorate.title).to eq resource.decorate.label
  end
  context 'when a child of another vocabulary' do
    let(:vocab) { FactoryGirl.create_for_repository(:ephemera_vocabulary, label: 'test parent vocabulary') }
    let(:resource) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryGirl.build(:ephemera_vocabulary)
      res.member_of_vocabulary_id = vocab.id
      adapter.persister.save(resource: res)
    end

    it 'retrieves the parent vocabulary' do
      expect(resource.decorate.vocabulary).to be_a EphemeraVocabulary
      expect(resource.decorate.vocabulary.label).to eq 'test parent vocabulary'
    end

    it 'exposes the label for the vocabulary' do
      expect(resource.decorate.vocabulary_label).to eq resource.decorate.vocabulary.label
    end
  end
  context 'when a parent of other vocabularies' do
    let(:resource) { FactoryGirl.create_for_repository(:ephemera_vocabulary) }
    before do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      child1 = FactoryGirl.build(:ephemera_vocabulary, label: 'test child vocabulary1')
      child1.member_of_vocabulary_id = resource.id
      adapter.persister.save(resource: child1)
      child2 = FactoryGirl.build(:ephemera_vocabulary, label: 'test child vocabulary2')
      child2.member_of_vocabulary_id = resource.id
      adapter.persister.save(resource: child2)
    end

    it 'retrieves the parent vocabulary' do
      expect(resource.decorate.categories.length).to eq 2
      expect(resource.decorate.categories.first).to be_a EphemeraVocabulary
      expect(resource.decorate.categories.first.label).to eq 'test child vocabulary1'
      expect(resource.decorate.categories.last).to be_a EphemeraVocabulary
      expect(resource.decorate.categories.last.label).to eq 'test child vocabulary2'
    end
  end
end
