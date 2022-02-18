# frozen_string_literal: true

require "rails_helper"

RSpec.describe Valkyrie1Migrator do
  describe ".call" do
    it "migrates EphemeraVocabulary and EphemeraTerm labels" do
      # Set up labels outside of array like done in previous Figgy
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      resource_factory = adapter.metadata_adapter.resource_factory
      vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary)
      term = FactoryBot.create_for_repository(:ephemera_term)
      resources = adapter.metadata_adapter.resources
      orm_vocabulary = resource_factory.from_resource(resource: vocabulary)
      orm_term = resource_factory.from_resource(resource: term)
      orm_vocabulary[:metadata][:label] = Array.wrap(orm_vocabulary[:metadata][:label]).first
      orm_term[:metadata][:label] = Array.wrap(orm_term[:metadata][:label]).first
      resources.where(id: orm_vocabulary[:id]).update(orm_vocabulary)
      resources.where(id: orm_term[:id]).update(orm_term)

      # Run migrator
      described_class.call

      # Ensure it's stored as an array now
      orm_vocabulary = resources.first(id: orm_vocabulary[:id])
      orm_term = resources.first(id: orm_term[:id])
      expect(orm_vocabulary[:metadata]["label"]).to eq ["test vocabulary"]
      expect(orm_term[:metadata]["label"]).to eq ["test term"]
    end
  end
end
