# frozen_string_literal: true
require "rails_helper"

RSpec.describe TombstoneMigrator do
  describe ".call" do
    it "migrates a Tombstone to a DeletionMarker resource" do
      query_service = ChangeSetPersister.default.query_service
      resource_id = Valkyrie::ID.new(SecureRandom.uuid)
      resource_title = "Test Title"
      original_filename = "Original File"
      parent_id = Valkyrie::ID.new(SecureRandom.uuid)
      preservation_object = FactoryBot.create_for_repository(:preservation_object)
      FactoryBot.create_for_repository(:tombstone,
                                        file_set_id: resource_id,
                                        file_set_title: resource_title,
                                        file_set_original_filename: original_filename,
                                        parent_id: parent_id,
                                        preservation_object: preservation_object)

      # Run migrator
      described_class.call

      tombstones = query_service.find_all_of_model(model: tombstones)
      deletion_marker = query_service.find_all_of_model(model: DeletionMarker).first

      expect(tombstones).to be_empty
      expect(deletion_marker.resource_id).to eq resource_id
      expect(deletion_marker.resource_title).to eq [resource_title]
      expect(deletion_marker.original_filename).to eq [original_filename]
      expect(deletion_marker.parent_id).to eq parent_id
      expect(deletion_marker.preservation_object.id).to eq preservation_object.id
    end
  end
end
