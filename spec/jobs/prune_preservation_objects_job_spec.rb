# frozen_string_literal: true
require "rails_helper"

RSpec.describe PrunePreservationObjectsJob do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { adapter.query_service }

  describe "#perform" do
    it "deletes all but the most recently created PreservationObject" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      FactoryBot.create_for_repository(:preservation_object, preserved_object_id: resource.id)
      FactoryBot.create_for_repository(:preservation_object, preserved_object_id: resource.id)
      po3 = FactoryBot.create_for_repository(:preservation_object, preserved_object_id: resource.id)

      described_class.perform_now(resource.id)
      resource = query_service.find_by(id: resource.id)
      preservation_objects = Wayfinder.for(resource).preservation_objects
      expect(preservation_objects.count).to eq 1
      expect(preservation_objects.first).to eq po3
    end
  end
end
