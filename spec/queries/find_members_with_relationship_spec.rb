# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindMembersWithRelationship do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_members_with_relationship" do
    it "returns members with `loaded_relationship` loaded" do
      genre = FactoryBot.create_for_repository(:ephemera_term, label: "Genre")
      genre2 = FactoryBot.create_for_repository(:ephemera_term, label: "Genre2")
      folder = FactoryBot.create_for_repository(:ephemera_folder, genre: [genre.id, genre2.id])
      folder2 = FactoryBot.create_for_repository(:ephemera_folder, genre: [genre.id])
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [folder.id, folder2.id])

      output = query.find_members_with_relationship(resource: project, relationship: :genre).to_a
      expect(output.first.loaded[:genre][0].label).to eq ["Genre"]
      expect(output.first.loaded[:genre][1].label).to eq ["Genre2"]
      expect(output.last.loaded[:genre][0].label).to eq ["Genre"]
    end
  end
end
