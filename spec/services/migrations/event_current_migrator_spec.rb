# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::EventCurrentMigrator do
  describe ".run" do
    it "populates the `current` attribute of each Event" do
      # note at the time of this migration all Events have type: cloud_fixity
      file_set = FactoryBot.create_for_repository(:file_set)
      resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [file_set.id])

      fs_metadata_node = FileMetadata.new(id: SecureRandom.uuid)
      fs_binary_node = FileMetadata.new(id: SecureRandom.uuid)
      resource_metadata_node = FileMetadata.new(id: SecureRandom.uuid)

      fs_pres_obj = FactoryBot.create_for_repository(:preservation_object, preserved_object_id: file_set.id, metadata_node: fs_metadata_node, binary_nodes: [fs_binary_node])
      res_pres_obj = FactoryBot.create_for_repository(:preservation_object, preserved_object_id: resource.id, metadata_node: resource_metadata_node)

      fs_event1 = FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: fs_pres_obj.id, child_property: "metadata_node", child_id: fs_pres_obj.metadata_node.id)
      fs_event2 = FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: fs_pres_obj.id, child_property: "metadata_node", child_id: fs_pres_obj.metadata_node.id)

      resource_event1 = FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: res_pres_obj.id, child_property: "metadata_node", child_id: res_pres_obj.metadata_node.id)
      resource_event2 = FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: res_pres_obj.id, child_property: "metadata_node", child_id: res_pres_obj.metadata_node.id)

      file_event1 = FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: fs_pres_obj.id, child_property: "binary_node", child_id: fs_pres_obj.binary_nodes.first.id)
      file_event2 = FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: fs_pres_obj.id, child_property: "binary_node", child_id: fs_pres_obj.binary_nodes.first.id)

      query_service = Valkyrie.config.metadata_adapter.query_service
      described_class.call

      expect(query_service.find_by(id: fs_event2.id).current).to eq true
      expect(query_service.find_by(id: file_event2.id).current).to eq true
      expect(query_service.find_by(id: resource_event2.id).current).to eq true

      expect(query_service.find_by(id: fs_event1.id).current).to be_falsey
      expect(query_service.find_by(id: file_event1.id).current).to be_falsey
      expect(query_service.find_by(id: resource_event1.id).current).to be_falsey
    end
  end
end
