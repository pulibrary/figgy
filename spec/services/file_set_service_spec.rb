# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileSetService do
  describe ".delete_all_from" do
    it "deletes all member file sets from a resource but no other member types" do
      resource = FactoryBot.create_for_repository(:scanned_map_with_raster_child, state: "pending")
      wayfinder = Wayfinder.for(resource)
      file_sets = wayfinder.file_sets
      raster_children = wayfinder.raster_resources
      expect(file_sets.count).to eq 1
      expect(raster_children.count).to eq 1

      described_class.delete_all_from(resource.id.to_s)
      reloaded = ChangeSetPersister.default.query_service.find_by(id: resource.id.to_s)
      wayfinder = Wayfinder.for(reloaded)
      file_sets = wayfinder.file_sets
      raster_children = wayfinder.raster_resources
      expect(file_sets.count).to eq 0
      expect(raster_children.count).to eq 1
    end
  end
end
