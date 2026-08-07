require "rails_helper"

RSpec.describe Migrations::FeaturableMigrator do
  let(:query_service) { ChangeSetPersister.default.query_service }

  describe ".call" do
    let(:csv_path) { Rails.root.join("tmp", "featurable_migration_spec.csv") }

    after do
      FileUtils.rm_f(csv_path)
    end

    it "features a resource in every collection it belongs to and writes a csv" do
      collection1 = FactoryBot.create_for_repository(:collection)
      collection2 = FactoryBot.create_for_repository(:collection)
      resource = FactoryBot.create_for_repository(
        :scanned_resource,
        member_of_collection_ids: [collection1.id, collection2.id],
        featurable: "1"
      )

      described_class.call(csv_path: csv_path)

      reloaded = query_service.find_by(id: resource.id)
      expect(reloaded.featurable.map(&:to_s)).to contain_exactly(collection1.id.to_s, collection2.id.to_s)

      doc = CSV.read(csv_path)
      expect(doc.first).to include(resource.id.to_s)
    end

    it "features an ephemera folder in its parent project" do
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

    it "sets featurable to empty for a resource where it was previously set to false" do
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

      described_class.call

      reloaded = query_service.find_by(id: resource.id)
      expect(reloaded.featurable.map(&:to_s)).to eq [collection1.id.to_s]
    end
  end
end
