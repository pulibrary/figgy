# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bag Roundtripping" do
  let(:exporter) do
    Bagit::BagExporter.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:bags),
      storage_adapter: Valkyrie::StorageAdapter.find(:bags),
      query_service: Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    )
  end
  let(:importer) do
    Bagit::BagImporter.new(
      bag_metadata_adapter: Valkyrie::MetadataAdapter.find(:bags),
      bag_storage_adapter: Valkyrie::StorageAdapter.find(:bags),
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk)
    )
  end
  context "when given an EphemeraFolder" do
    it "exports vocabularies if they need to be" do
      vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary)
      term = FactoryBot.create_for_repository(:ephemera_term, member_of_vocabulary_id: vocabulary.id)
      folder = FactoryBot.create_for_repository(:ephemera_folder, genre: term.id)
      exporter.export(resource: folder)
      importer.metadata_adapter.persister.wipe!

      importer.import(id: folder.id)

      expect(importer.metadata_adapter.query_service.find_all_of_model(model: EphemeraFolder).to_a.length).to eq 1
      expect(importer.metadata_adapter.query_service.find_all_of_model(model: EphemeraTerm).to_a.length).to eq 1
      expect(importer.metadata_adapter.query_service.find_all_of_model(model: EphemeraVocabulary).to_a.length).to eq 1
    end
    it "doesn't import vocabularies that already exist" do
      vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary)
      term = FactoryBot.create_for_repository(:ephemera_term, member_of_vocabulary_id: vocabulary.id)
      folder = FactoryBot.create_for_repository(:ephemera_folder, genre: term.id)
      exporter.export(resource: folder)
      importer.metadata_adapter.persister.wipe!
      output = importer.metadata_adapter.persister.save(resource: vocabulary, external_resource: true)

      importer.import(id: folder.id)

      expect(importer.metadata_adapter.query_service.find_all_of_model(model: EphemeraFolder).to_a.length).to eq 1
      expect(importer.metadata_adapter.query_service.find_all_of_model(model: EphemeraTerm).to_a.length).to eq 1
      expect(importer.metadata_adapter.query_service.find_all_of_model(model: EphemeraVocabulary).to_a.length).to eq 1

      reloaded_vocabulary = importer.metadata_adapter.query_service.find_by(id: output.id)
      expect(reloaded_vocabulary.created_at).to eq output.created_at
    end
  end
end
