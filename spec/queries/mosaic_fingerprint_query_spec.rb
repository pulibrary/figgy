# frozen_string_literal: true

require "rails_helper"

RSpec.describe MosaicFingerprintQuery do
  def create_raster_set
    file_set1 = FactoryBot.create_for_repository(:geo_raster_cloud_file)
    file_set2 = FactoryBot.create_for_repository(:geo_raster_cloud_file)
    child = FactoryBot.create_for_repository(:raster_resource, member_ids: [file_set1.id, file_set2.id])
    FactoryBot.create_for_repository(:raster_resource, member_ids: [child.id])
  end

  def create_raster_scanned_map
    raster_file_set1 = FactoryBot.create_for_repository(:geo_raster_cloud_file)
    scanned_map_file_set1 = FactoryBot.create_for_repository(:geo_image_file_set)
    raster1 = FactoryBot.create_for_repository(:raster_resource, member_ids: [raster_file_set1.id])
    FactoryBot.create_for_repository(:scanned_map, member_ids: [raster1.id, scanned_map_file_set1.id])
  end

  let(:query_service) { ChangeSetPersister.default.query_service }

  context "when given a Scanned Map with Rasters" do
    it "returns a uniquely identifiable fingerprint" do
      scanned_map = create_raster_scanned_map
      map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map.id])

      expect(query_service.custom_queries.mosaic_fingerprint_for(id: map_set.id)).to eq query_service.custom_queries.mosaic_fingerprint_for(id: map_set.id)
    end
    it "has the same fingerprint after deleting the scanned map file set" do
      scanned_map = create_raster_scanned_map
      map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map.id])

      start_fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: map_set.id)
      ChangeSetPersister.default.persister.delete(resource: Wayfinder.for(scanned_map).file_sets.first)

      expect(start_fingerprint).to eq query_service.custom_queries.mosaic_fingerprint_for(id: map_set.id)
    end
    it "has a different fingerprint after adding a new raster" do
      scanned_map1 = create_raster_scanned_map
      map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map1.id])

      start_fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: map_set.id)
      scanned_map2 = create_raster_scanned_map
      map_set.member_ids += [scanned_map2.id]
      ChangeSetPersister.default.persister.save(resource: map_set)

      expect(start_fingerprint).not_to eq query_service.custom_queries.mosaic_fingerprint_for(id: map_set.id)
    end
  end

  context "when given a RasterSet" do
    it "returns a uniquely identiable fingerprint" do
      raster_set = create_raster_set

      expect(query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)).to eq query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)
    end
    it "doesn't change the fingerprint if the order of files is changed" do
      raster_set = create_raster_set
      first_fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)
      child = Wayfinder.for(raster_set).members.first
      child.member_ids = child.member_ids.reverse
      ChangeSetPersister.default.metadata_adapter.persister.save(resource: child)

      expect(query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)).to eq first_fingerprint
    end
    it "changes the fingerprint if a FileSet is deleted" do
      raster_set = create_raster_set
      first_fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)
      child = Wayfinder.for(raster_set).members.first
      grandchild = Wayfinder.for(child).members.first
      ChangeSetPersister.default.metadata_adapter.persister.delete(resource: grandchild)

      expect(query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)).not_to eq first_fingerprint
    end
    it "returns the raster set ID if there are no file sets" do
      raster_set = create_raster_set
      child = Wayfinder.for(raster_set).members.first
      child.member_ids = []
      ChangeSetPersister.default.metadata_adapter.persister.save(resource: child)

      expect(query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)).to eq raster_set.id.to_s
    end
  end
end
