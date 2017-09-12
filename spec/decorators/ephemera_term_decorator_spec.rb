# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraTermDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:ephemera_term) }
  describe "decoration" do
    it "decorates an EphemeraTerm" do
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
  it 'exposes the title as the label' do
    expect(resource.decorate.title).to eq resource.decorate.label
  end
  context 'when a child of a vocabulary' do
    let(:vocab) { FactoryGirl.create_for_repository(:ephemera_vocabulary, label: 'test parent vocabulary') }
    let(:resource) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryGirl.build(:ephemera_term)
      res.member_of_vocabulary_id = vocab.id
      adapter.persister.save(resource: res)
    end

    it 'retrieves the parent vocabulary' do
      expect(resource.decorate.vocabulary).to be_a EphemeraVocabulary
      expect(resource.decorate.vocabulary.label).to eq 'test parent vocabulary'
    end
  end
end
