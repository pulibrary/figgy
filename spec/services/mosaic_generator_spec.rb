# frozen_string_literal: true
require "rails_helper"

RSpec.describe MosaicGenerator do
  describe "#generate" do
    it "returns a path" do
      raster_set = FactoryBot.create_for_repository(:raster_set)
      generator = described_class.new(resource: raster_set)
      base_path = Valkyrie::StorageAdapter.find(:cloud_geo_derivatives).storage_adapter.base_path

      path = Valkyrie::Storage::Disk::BucketedStorage.new(base_path: base_path).generate(resource: raster_set, original_filename: "mosaic.json", file: nil).to_s

      expect(generator.generate).to eq path
    end
  end
end
