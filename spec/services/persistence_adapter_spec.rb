# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PersistenceAdapter do
  let(:query_adapter) { QueryAdapter.new(query_service: query_service, model: EphemeraVocabulary) }
  let(:adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { adapter.query_service }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:persistence_adapter) { described_class.new(change_set_persister: change_set_persister, model: EphemeraVocabulary) }

  describe "#create" do
    it "persists a new resource" do
      persistence_adapter.create(label: 'test vocabulary')

      expect(query_adapter.all).not_to be_empty
      expect(query_adapter.all.first).to be_a EphemeraVocabularyDecorator
      expect(query_adapter.all.first.label).to eq 'test vocabulary'
    end
    context 'when using a non-existent model' do
      before do
        class MyResource < Valhalla::Resource; end
      end

      after do
        Object.send(:remove_const, :MyResource)
      end

      let(:persistence_adapter) { described_class.new(change_set_persister: change_set_persister, model: MyResource) }
      it 'raises an error' do
        expect { persistence_adapter.create(label: 'testing error') }.to raise_error(NotImplementedError, 'Change Set for MyResource not implemented.')
      end
    end
  end
end
