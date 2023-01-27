# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindNeverPreservedChildIds do
  context "when there is a resource with a PreservationObject, and some children with and some children without PreservationObjects" do
    it "returns the child IDs that don't have PreservationObjects", db_cleaner_deletion: true do
      file1 = FactoryBot.create_for_repository(:file_set)
      FactoryBot.create_for_repository(:preservation_object, preserved_object_id: file1.id)
      file2 = FactoryBot.create_for_repository(:file_set)
      resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [file1.id, file2.id])
      FactoryBot.create_for_repository(:preservation_object, preserved_object_id: resource.id)

      output = ChangeSetPersister.default.query_service.custom_queries.find_never_preserved_child_ids(resource: resource)

      expect(output).to eq [file2.id]
    end
  end
end
