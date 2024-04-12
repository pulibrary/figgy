# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::ChildResourceCollectionMigrator do
  describe ".call" do
    it "Removes collections from any member of the given collection that has a parent" do
      collection = FactoryBot.create_for_repository(:collection)
      child1 = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id])
      child2 = FactoryBot.create_for_repository(:scanned_resource)
      mvw = FactoryBot.create_for_repository(:scanned_resource, member_ids: [child1.id, child2.id], member_of_collection_ids: [collection.id])
      scanned_resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id])
      logger = Logger.new(nil)
      allow(logger).to receive(:info)

      described_class.new(collection_id: collection.id, logger: logger).run

      query_service = ChangeSetPersister.default.query_service

      expect(logger).to have_received(:info).with("Found 1 child resources as members of collection")
      child1 = query_service.find_by(id: child1.id)
      child2 = query_service.find_by(id: child2.id)
      mvw = query_service.find_by(id: mvw.id)
      scanned_resource = query_service.find_by(id: scanned_resource.id)
      expect(child1.member_of_collection_ids).not_to be_present
      expect(child2.member_of_collection_ids).not_to be_present
      expect(mvw.member_of_collection_ids).to eq [collection.id]
      expect(scanned_resource.member_of_collection_ids).to eq [collection.id]
    end
  end
end
