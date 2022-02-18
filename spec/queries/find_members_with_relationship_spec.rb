# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindMembersWithRelationship do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_members_with_relationship" do
    it "returns members with `loaded_relationship` loaded" do
      genre = FactoryBot.create_for_repository(:ephemera_term, label: "Subject1")
      genre2 = FactoryBot.create_for_repository(:ephemera_term, label: "Subject2")
      folder = FactoryBot.create_for_repository(:ephemera_folder, geo_subject: [genre.id, genre2.id])
      folder2 = FactoryBot.create_for_repository(:ephemera_folder, geo_subject: [genre.id])
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [folder.id, folder2.id])

      output = query.find_members_with_relationship(resource: project, relationship: :geo_subject).to_a
      expect(output.first.loaded[:geo_subject][0].label).to eq ["Subject1"]
      expect(output.first.loaded[:geo_subject][1].label).to eq ["Subject2"]
      expect(output.last.loaded[:geo_subject][0].label).to eq ["Subject1"]
    end
  end
end
