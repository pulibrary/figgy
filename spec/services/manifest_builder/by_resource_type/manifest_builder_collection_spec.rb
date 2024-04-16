# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilder do
  with_queue_adapter :inline
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  context "when given a collection" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: collection.id), nil, ability) }
    let(:ability) { Ability.new(user) }
    let(:user) { FactoryBot.create(:admin) }
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:change_set) { CollectionChangeSet.new(collection) }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id], member_ids: scanned_resource_2.id, thumbnail_id: scanned_resource_2.id) }
    let(:scanned_resource_2) { FactoryBot.create_for_repository(:scanned_resource) }

    before do
      scanned_resource
      output = change_set_persister.save(change_set: change_set)
      change_set = CollectionChangeSet.new(output)
      change_set_persister.save(change_set: change_set)
    end
    it "builds a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["@type"]).to eq "sc:Collection"
      expect(output["metadata"]).to be_kind_of Array
      expect(output["metadata"]).not_to be_empty
      expect(output["metadata"].first).to include "label" => "Exhibit", "value" => [collection.decorate.slug]
      expect(output["manifests"].length).to eq 1
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/scanned_resources/#{scanned_resource.id}/manifest"
      expect(output["viewingDirection"]).to eq nil
    end
    context "when given a user without access to the manifest" do
      let(:user) { FactoryBot.create(:user) }
      it "doesn't display those child manifests" do
        output = manifest_builder.build
        expect(output).to be_kind_of Hash
        expect(output["@type"]).to eq "sc:Collection"
        expect(output["metadata"]).to be_kind_of Array
        expect(output["metadata"]).not_to be_empty
        expect(output["metadata"].first).to include "label" => "Exhibit", "value" => [collection.decorate.slug]
        expect(output["manifests"].length).to eq 0
        expect(output["viewingDirection"]).to eq nil
      end
    end
  end
end 