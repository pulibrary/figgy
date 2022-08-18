# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mutations::UpdateResource do
  describe "schema" do
    subject { described_class }
    it { is_expected.to have_field(:resource) }
    it { is_expected.to have_field(:errors) }
    it {
      is_expected.to accept_arguments(
        id: "ID!",
        viewingHint: "String",
        label: "String",
        memberIds: "[String!]",
        startPage: "String",
        viewingDirection: "Types::ViewingDirectionEnum",
        thumbnailId: "String"
      )
    }
  end

  context "when given permission" do
    context "when given an invalid viewing hint" do
      it "returns an error" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        mutation = create_mutation

        output = mutation.resolve(id: resource.id, viewing_hint: "bad")
        expect(output[:errors]).to eq ["Viewing hint is not included in the list"]
      end
    end
    context "when given good data" do
      it "updates the record" do
        file1 = fixture_file_upload("files/abstract.tiff", "image/tiff")
        resource = FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "paged", title: "label", files: [file1], viewing_direction: "left-to-right", thumbnail_id: "bla")
        file_set1 = resource.decorate.members.first
        mutation = create_mutation

        output = mutation.resolve(id: resource.id, viewing_hint: "individuals", label: "label2", start_page: file_set1.id.to_s)
        expect(output[:resource].viewing_hint).to eq ["individuals"]
        expect(output[:resource].title).to eq ["label2"]
        expect(output[:resource].start_canvas).to eq [file_set1.id]
        expect(output[:resource].viewing_direction).to eq ["left-to-right"]
        expect(output[:resource].thumbnail_id).to eq [Valkyrie::ID.new("bla")]
      end
    end
    context "when given an invalid viewing direction" do
      it "returns an error" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        mutation = create_mutation

        output = mutation.resolve(id: resource.id, viewing_direction: "bad")
        expect(output[:errors]).to eq ["Viewing direction is not included in the list"]
      end
    end
    context "when reordering" do
      it "errors when missing some IDs" do
        member1 = FactoryBot.create_for_repository(:file_set)
        member2 = FactoryBot.create_for_repository(:file_set)
        resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [member1.id, member2.id])
        mutation = create_mutation

        output = mutation.resolve(id: resource.id, member_ids: [member1.id.to_s])
        expect(output[:errors]).to eq ["Member ids can only be used to re-order."]
      end
      it "errors when there are additional IDs" do
        member1 = FactoryBot.create_for_repository(:file_set)
        member2 = FactoryBot.create_for_repository(:file_set)
        member3 = FactoryBot.create_for_repository(:file_set)
        resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [member1.id, member2.id])
        mutation = create_mutation

        output = mutation.resolve(id: resource.id, member_ids: [member1.id.to_s, member2.id.to_s, member3.id.to_s])
        expect(output[:errors]).to eq ["Member ids can only be used to re-order."]
      end
      it "works for re-ordering" do
        member1 = FactoryBot.create_for_repository(:file_set)
        member2 = FactoryBot.create_for_repository(:file_set)
        resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [member1.id, member2.id])
        mutation = create_mutation

        output = mutation.resolve(id: resource.id, member_ids: [member2.id.to_s, member1.id.to_s])
        expect(output[:errors]).to be_nil
        expect(output[:resource].member_ids).to eq [member2.id, member1.id]
      end

      context "when there is a non-existant member id in the resource" do
        it "does not error" do
          member1 = FactoryBot.create_for_repository(:file_set)
          member2 = FactoryBot.create_for_repository(:file_set)
          id = Valkyrie::ID.new(SecureRandom.uuid)
          resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [member1.id, member2.id, id])
          mutation = create_mutation

          output = mutation.resolve(id: resource.id, member_ids: [member2.id.to_s, member1.id.to_s])
          expect(output[:errors]).to be_nil
          expect(output[:resource].member_ids).to eq [member2.id, member1.id]
        end
      end
    end
  end

  context "without permission" do
    it "returns an error and nothing in resource" do
      resource = FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "paged")
      mutation = create_mutation(update_permission: false, read_permission: false)

      output = mutation.resolve(id: resource.id, viewing_hint: "individuals")
      expect(output[:resource]).to be_nil
      expect(output[:errors]).to eq ["You do not have permissions on this resource."]
    end
  end

  context "when you have read permission, but no update permission" do
    it "returns an error with the unchanged resource" do
      resource = FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "paged")
      mutation = create_mutation(update_permission: false, read_permission: true)

      output = mutation.resolve(id: resource.id, viewing_hint: "individuals")
      expect(output[:resource].viewing_hint).to eq ["paged"]
      expect(output[:errors]).to eq ["You do not have permissions on this resource."]
    end
  end

  def create_mutation(update_permission: true, read_permission: true)
    ability = instance_double(Ability)
    allow(ability).to receive(:can?).with(:update, anything).and_return(update_permission)
    allow(ability).to receive(:can?).with(:read, anything).and_return(read_permission)
    described_class.new(object: nil, context: { ability: ability, change_set_persister: GraphqlController.change_set_persister })
  end
end
