require "rails_helper"

RSpec.describe Migrations::FeaturableMigrator do
  let(:query_service) { ChangeSetPersister.default.query_service }

  describe ".call" do
    it "highlights a featured resource in every collection it belongs to" do
      collection1 = FactoryBot.create_for_repository(:collection)
      collection2 = FactoryBot.create_for_repository(:collection)
      resource = FactoryBot.create_for_repository(
        :scanned_resource,
        member_of_collection_ids: [collection1.id, collection2.id],
        featurable: "1"
      )

      described_class.call

      reloaded = query_service.find_by(id: resource.id)
      expect(reloaded.featurable.map(&:to_s)).to contain_exactly(collection1.id.to_s, collection2.id.to_s)
    end

    it "highlights a featured ephemera folder in its ancestor project" do
      collection = FactoryBot.create_for_repository(:collection)
      folder = FactoryBot.create_for_repository(
        :ephemera_folder,
        member_of_collection_ids: [collection.id],
        featurable: "1"
      )
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [folder.id])

      described_class.call

      reloaded = query_service.find_by(id: folder.id)
      expect(reloaded.featurable.map(&:to_s)).to contain_exactly(collection.id.to_s, project.id.to_s)
    end

    it "migrates resources stored with a boolean rather than a string" do
      collection = FactoryBot.create_for_repository(:collection)
      map = FactoryBot.create_for_repository(
        :scanned_map,
        member_of_collection_ids: [collection.id],
        featurable: true
      )

      described_class.call

      reloaded = query_service.find_by(id: map.id)
      expect(reloaded.featurable.map(&:to_s)).to eq [collection.id.to_s]
    end

    it "clears the flag for resources that were not featured" do
      collection = FactoryBot.create_for_repository(:collection)
      resource = FactoryBot.create_for_repository(
        :scanned_resource,
        member_of_collection_ids: [collection.id],
        featurable: "0"
      )

      described_class.call

      reloaded = query_service.find_by(id: resource.id)
      expect(reloaded.featurable).to be_empty
    end

    it "leaves already migrated resources alone" do
      collection1 = FactoryBot.create_for_repository(:collection)
      collection2 = FactoryBot.create_for_repository(:collection)
      resource = FactoryBot.create_for_repository(
        :scanned_resource,
        member_of_collection_ids: [collection1.id, collection2.id],
        featurable: [collection1.id]
      )

      expect(described_class.call).to eq 0

      reloaded = query_service.find_by(id: resource.id)
      expect(reloaded.featurable.map(&:to_s)).to eq [collection1.id.to_s]
    end
  end
end
