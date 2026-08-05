require "rails_helper"

RSpec.describe FeaturableProperty do
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { change_set_persister.query_service }

  describe "#featurable" do
    it "holds the ids of the collections a resource is highlighted in" do
      collection = FactoryBot.create_for_repository(:collection)
      resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id])
      change_set = ChangeSet.for(resource)

      change_set.validate(featurable: [collection.id.to_s])
      output = change_set_persister.save(change_set: change_set)

      expect(output.featurable.map(&:to_s)).to eq [collection.id.to_s]
    end

    it "drops the blank value the form submits when every box is unchecked" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      change_set = ChangeSet.for(resource)

      change_set.validate(featurable: [""])
      output = change_set_persister.save(change_set: change_set)

      expect(output.featurable).to be_empty
    end

    it "ignores boolean values left over from before the property held ids" do
      resource = FactoryBot.create_for_repository(:scanned_resource, featurable: "1")

      expect(ChangeSet.for(resource).featurable).to be_empty
    end

    it "replaces leftover boolean values when the form is submitted" do
      collection = FactoryBot.create_for_repository(:collection)
      folder = FactoryBot.create_for_repository(
        :ephemera_folder,
        member_of_collection_ids: [collection.id],
        featurable: "1"
      )
      change_set = ChangeSet.for(folder)

      change_set.validate(featurable: ["", collection.id.to_s])
      output = change_set_persister.save(change_set: change_set)

      expect(output.featurable.map(&:to_s)).to eq [collection.id.to_s]
    end
  end

  describe "#featurable_options" do
    it "lists the collections a resource belongs to, sorted by title" do
      collection1 = FactoryBot.create_for_repository(:collection, title: "Zebras")
      collection2 = FactoryBot.create_for_repository(:collection, title: "Aardvarks")
      resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection1.id, collection2.id])

      expect(ChangeSet.for(resource).featurable_options).to eq(
        [
          { "id" => collection2.id.to_s, "label" => "Aardvarks" },
          { "id" => collection1.id.to_s, "label" => "Zebras" }
        ]
      )
    end

    it "adds the ancestor ephemera project after the collections" do
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

    it "picks up collections added in the current edit" do
      collection = FactoryBot.create_for_repository(:collection, title: "Newly Added")
      resource = FactoryBot.create_for_repository(:scanned_resource)
      change_set = ChangeSet.for(resource)

      change_set.validate(member_of_collection_ids: [collection.id.to_s])

      expect(change_set.featurable_options).to eq([{ "id" => collection.id.to_s, "label" => "Newly Added" }])
    end

    it "is empty for a resource with no collections or ephemera project" do
      resource = FactoryBot.create_for_repository(:scanned_resource)

      expect(ChangeSet.for(resource).featurable_options).to be_empty
    end

    it "is empty for an unsaved resource" do
      expect(ScannedResourceChangeSet.new(ScannedResource.new).featurable_options).to be_empty
    end
  end
end
