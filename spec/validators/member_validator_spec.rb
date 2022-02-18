# frozen_string_literal: true

require "rails_helper"

RSpec.describe MemberValidator do
  subject(:validator) { described_class.new }

  context "when given a resource with no members" do
    it "adds no errors" do
      resource = FactoryBot.build(:scanned_resource)
      change_set = ChangeSet.for(resource)

      validator.validate(change_set)

      expect(change_set.errors).to be_blank
    end
  end
  context "when given a resource with a bad member ID" do
    it "gives an error about it" do
      resource = FactoryBot.build(:scanned_resource, member_ids: [Valkyrie::ID.new("yo")])
      change_set = ChangeSet.for(resource)

      validator.validate(change_set)

      expect(change_set.errors[:member_ids]).to eq ["yo is not a valid UUID"]
    end
  end
  context "when given a member ID that has no resource attached" do
    it "gives an error about it" do
      adapter = Valkyrie.config.metadata_adapter
      child = FactoryBot.create_for_repository(:scanned_resource)
      adapter.persister.delete(resource: child)
      resource = FactoryBot.build(:scanned_resource, member_ids: [child.id])
      change_set = ChangeSet.for(resource)

      validator.validate(change_set)

      expect(change_set.errors[:member_ids]).to eq ["#{child.id} does not resolve to a resource"]
    end
  end
  context "when given a valid member" do
    it "adds no errors" do
      child = FactoryBot.create_for_repository(:scanned_resource)
      resource = FactoryBot.build(:scanned_resource, member_ids: [child.id])
      change_set = ChangeSet.for(resource)

      validator.validate(change_set)

      expect(change_set.errors).to be_blank
    end
  end
end
