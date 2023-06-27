# frozen_string_literal: true
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe GdalCharacterizationService::Raster do
  let(:file_characterization_service) { described_class }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/geo_metadata/iso.xml", "application/xml") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:raster_resource) do
    change_set_persister.save(change_set: RasterResourceChangeSet.new(RasterResource.new, files: [file]))
  end
  let(:decorated_raster_resources) { query_service.find_members(resource: raster_resource) }
  let(:valid_file_set) { decorated_raster_resources.first }

  context "with a geotiff" do
    let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tiff") }
    let(:tika_output) { tika_geotiff_output }

    it "sets the correct mime_type on the file_set on characterize" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["image/tiff; gdal-format=GTiff"]
    end
  end

  context "with a geotiff containing a single quote in the name" do
    let(:file) { fixture_file_upload("files/raster/geo'tiff.tif", "image/tiff") }
    let(:tika_output) { tika_geotiff_output }

    it "sets the correct mime_type on the file_set on characterize" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["image/tiff; gdal-format=GTiff"]
    end
  end

  context "with an arcgrid file" do
    let(:file) { fixture_file_upload("files/raster/arcgrid.zip", "application/zip") }
    let(:tika_output) { tika_arcgrid_output }

    it "sets the correct mime_type on the file_set on characterize" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["application/octet-stream; gdal-format=AIG"]
    end
  end

  context "with a non-georaster file" do
    let(:tika_output) { tika_xml_output }

    it "sets the correct mime_type on the file_set on characterize" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["application/xml"]
    end
  end

  describe "#valid?" do
    let(:decorator) { instance_double(FileSetDecorator, parent: parent) }

    before do
      allow(valid_file_set).to receive(:decorate).and_return(decorator)
    end

    context "with a scanned resource parent" do
      let(:parent) { ScannedResource.new }
      it "isn't valid" do
        expect(described_class.new(file_set: valid_file_set, persister: persister).valid?).to be false
      end
    end
  end
end
