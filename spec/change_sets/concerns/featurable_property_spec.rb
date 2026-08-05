require "rails_helper"

RSpec.describe FeaturableProperty do
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { change_set_persister.query_service }

  describe "#featurable" do
    it "ignores legacy boolean values" do
      resource = FactoryBot.create_for_repository(:scanned_resource, featurable: "1")

      expect(ChangeSet.for(resource).featurable).to be_empty
    end
  end

  describe "#featurable_options" do
    it "lists the collections sorted by title" do
      collection1 = FactoryBot.create_for_repository(:collection, title: "Zebras")
      collection2 = FactoryBot.create_for_repository(:collection, title: "Ant Eaters")
      resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection1.id, collection2.id])

      expect(ChangeSet.for(resource).featurable_options).to eq(
        [
          { "id" => collection2.id.to_s, "label" => "Ant Eaters" },
          { "id" => collection1.id.to_s, "label" => "Zebras" }
        ]
      )
    end

    it "adds the ephemera project after the collections" do
      collection = FactoryBot.create_for_repository(:collection, title: "A Collection")
      folder = FactoryBot.create_for_repository(:ephemera_folder, member_of_collection_ids: [collection.id])
      box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id])
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id])

      expect(ChangeSet.for(folder).featurable_options).to eq(
        [
          { "id" => collection.id.to_s, "label" => "A Collection" },
          { "id" => project.id.to_s, "label" => project.title.first }
        ]
      )
    end

    it "is empty when a resource has no collections or ephemera projects" do
      resource = FactoryBot.create_for_repository(:scanned_resource)

      expect(ChangeSet.for(resource).featurable_options).to be_empty
    end
  end
end
