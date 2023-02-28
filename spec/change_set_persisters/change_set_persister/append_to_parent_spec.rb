# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChangeSetPersister::AppendToParent do
  with_queue_adapter :inline
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { change_set_persister.query_service }

  describe "#run_before_save" do
    context "when adding to a new parent" do
      it "removes the resource from all its collections" do
        collection1 = FactoryBot.create_for_repository(:collection)
        resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection1.id])

        parent = FactoryBot.create_for_repository(:scanned_resource)
        change_set = ChangeSet.for(resource)
        change_set.validate(append_id: parent.id.to_s)

        output = change_set_persister.save(change_set: change_set)
        expect(output.member_of_collection_ids).to be_empty
      end
    end

    context "when not adding to a new parent" do
      it "keeps all the resources' collections" do
        collection1 = FactoryBot.create_for_repository(:collection)
        resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection1.id])

        change_set = ChangeSet.for(resource)

        output = change_set_persister.save(change_set: change_set)
        expect(output.member_of_collection_ids).not_to be_empty
      end
    end

    context "when trying to add to itself as a parent" do
      it "keeps all the its collections" do
        collection1 = FactoryBot.create_for_repository(:collection)
        resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection1.id])

        change_set = ChangeSet.for(resource)
        change_set.validate(append_id: resource.id.to_s)

        output = change_set_persister.save(change_set: change_set)
        expect(output.member_of_collection_ids).not_to be_empty
      end
    end

    context "when creating an ephemera folder" do
      it "keeps the collections" do
        collection1 = FactoryBot.create_for_repository(:collection)
        resource = FactoryBot.create_for_repository(:ephemera_folder, member_of_collection_ids: [collection1.id])
        parent = FactoryBot.create_for_repository(:ephemera_box)

        change_set = ChangeSet.for(resource)
        change_set.validate(append_id: parent.id.to_s)

        output = change_set_persister.save(change_set: change_set)
        expect(output.member_of_collection_ids).not_to be_empty
      end
    end
  end

  describe "#run_after_save" do
    it "appends a child via #append_id" do
      parent = FactoryBot.create_for_repository(:scanned_resource)
      resource = FactoryBot.build(:scanned_resource)
      change_set = ChangeSet.for(resource)
      change_set.validate(append_id: parent.id.to_s)

      output = change_set_persister.save(change_set: change_set)
      reloaded = query_service.find_by(id: parent.id)
      expect(reloaded.member_ids).to eq [output.id]
      expect(reloaded.thumbnail_id).to eq [output.id]
      solr_record = Blacklight.default_index.connection.get("select", params: { qt: "document", q: "id:#{output.id}" })["response"]["docs"][0]
      expect(solr_record["member_of_ssim"]).to eq ["id-#{parent.id}"]
      expect(output.cached_parent_id).to eq reloaded.id
    end

    it "will not append to the same parent twice" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: resource.id)
      change_set = ChangeSet.for(resource)
      change_set.validate(append_id: parent.id.to_s)

      output = change_set_persister.save(change_set: change_set)
      reloaded = query_service.find_by(id: parent.id)

      expect(reloaded.member_ids).to eq [output.id]
      expect(reloaded.thumbnail_id).to eq [output.id]
      solr_record = Blacklight.default_index.connection.get("select", params: { qt: "document", q: "id:#{output.id}" })["response"]["docs"][0]
      expect(solr_record["member_of_ssim"]).to eq ["id-#{parent.id}"]
    end

    it "moves a child from another parent via #append_id" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      old_parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: resource.id)
      new_parent = FactoryBot.create_for_repository(:scanned_resource)

      change_set = ChangeSet.for(resource)
      change_set.validate(append_id: new_parent.id.to_s)
      output = change_set_persister.save(change_set: change_set)

      new_reloaded = query_service.find_by(id: new_parent.id)
      old_reloaded = query_service.find_by(id: old_parent.id)

      expect(new_reloaded.member_ids).to eq [output.id]
      expect(new_reloaded.thumbnail_id).to eq [output.id]

      expect(old_reloaded.member_ids).to eq []
      expect(old_reloaded.thumbnail_id).to be_blank

      solr_record = Blacklight.default_index.connection.get("select", params: { qt: "document", q: "id:#{output.id}" })["response"]["docs"][0]
      expect(solr_record["member_of_ssim"]).to eq ["id-#{new_parent.id}"]
    end

    it "will not append a resource as a child of itself" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      change_set = ChangeSet.for(resource)
      change_set.validate(append_id: resource.id.to_s)

      output = change_set_persister.save(change_set: change_set)
      expect(output.member_ids).to eq []
    end
  end
end
