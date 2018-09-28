# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindMembersWithInverseRelationship do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_members_with_inverse_relationship" do
    it "returns members with `loaded_relationship` loaded" do
      file_set = FactoryBot.create_for_repository(:file_set)
      file_set2 = FactoryBot.create_for_repository(:file_set)
      FactoryBot.create_for_repository(:file_set)
      parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: [file_set.id, file_set2.id])
      parent2 = FactoryBot.create_for_repository(:scanned_resource, member_ids: [file_set2.id])

      output = query.find_members_with_inverse_relationship(resource: parent, relationship: :member_ids, key: :parents)

      expect(output.map(&:id)).to eq [file_set.id, file_set2.id]
      expect(output.first.loaded[:parents].map(&:id)).to eq [parent.id]
      expect(output.last.loaded[:parents].map(&:id)).to contain_exactly parent.id, parent2.id
    end
  end
end
