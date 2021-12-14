# frozen_string_literal: true

require "rails_helper"

RSpec.describe MosaicFingerprintQuery do
  def create_raster_set
    file_set1 = FactoryBot.create_for_repository(:geo_raster_cloud_file)
    file_set2 = FactoryBot.create_for_repository(:geo_raster_cloud_file)
    child = FactoryBot.create_for_repository(:raster_resource, member_ids: [file_set1.id, file_set2.id])
    FactoryBot.create_for_repository(:raster_resource, member_ids: [child.id])
  end

  let(:query_service) { ChangeSetPersister.default.query_service }

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
