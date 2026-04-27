require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe GdalCharacterizationService::Vector do
  let(:file_characterization_service) { described_class }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:vector_resource) do
    change_set_persister.save(change_set: VectorResourceChangeSet.new(VectorResource.new, files: [file]))
  end
  let(:decorated_vector_resources) { query_service.find_members(resource: vector_resource) }
  let(:valid_file_set) { decorated_vector_resources.first }

  context "with a geojson file" do
    let(:file) { fixture_file_upload("files/vector/geo.json", "application/vnd.geo+json") }
    let(:tika_output) { tika_geojson_output }

    it "sets the correct mime_type and geometry attributes on the file_set on characterize" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["application/vnd.geo+json"]
      expect(new_file_set.original_file.geometry).to eq ["Multi Polygon"]
    end

    it "populates checksum, size, and geometry" do
      info = instance_double(
        GeoDerivatives::Processors::Vector::Info,
        driver: "GeoJSON",
        geom: "Multi Polygon"
      )
      allow(GeoDerivatives::Processors::Vector::Info).to receive(:new).and_return(info)

      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      original_file = new_file_set.original_file
      geojson_size = File.size(Rails.root.join("spec", "fixtures", "files", "vector", "geo.json"))

      expect(original_file.geometry).to eq ["Multi Polygon"]
      expect(original_file.size).to eq [geojson_size]
      expect(original_file.checksum.first).to be_a(MultiChecksum)
      expect(original_file.error_message).to be_empty
    end
  end

  context "with a geojson file containing a single quote in the name" do
    let(:file) { fixture_file_upload("files/vector/g'eo.json", "application/vnd.geo+json") }
    let(:tika_output) { tika_geojson_output }

    it "sets the correct mime_type and geometry attributes on the file_set on characterize" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["application/vnd.geo+json"]
      expect(new_file_set.original_file.geometry).to eq ["Multi Polygon"]
    end
  end

  context "with a geojson file with an unsafe filename" do
    let(:file) { fixture_file_upload("files/vector/geo_&_unsafe.json", "application/vnd.geo+json") }
    let(:tika_output) { tika_geojson_output }

    it "sets the correct mime_type and geometry attributes on the file_set on characterize" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["application/vnd.geo+json"]
      expect(new_file_set.original_file.geometry).to eq ["Multi Polygon"]
    end
  end

  context "when provided with a shapefile that cannot be characterized", run_real_characterization: true do
    let(:file) { fixture_file_upload("files/vector/invalid-shapefile.zip", "application/zip") }
    let(:resource) do
      change_set_persister.save(change_set: VectorResourceChangeSet.new(VectorResource.new, files: [file]))
    end
    let(:invalid_file_set) { decorated_vector_resources.first }

    it "adds an error message to the file set and raises an error" do
      expect { described_class.new(file_set: invalid_file_set, persister: persister).characterize }.to raise_error(GeoDerivatives::OgrError)
      file_set = query_service.find_by(id: invalid_file_set.id)
      expect(file_set.file_metadata[0].geometry).to be_empty
      expect(file_set.file_metadata[0].error_message.first).to start_with "Error during characterization:"
    end
  end

  context "when vector characterization fails and then succeeds", run_real_characterization: true do
    let(:file) { fixture_file_upload("files/vector/shapefile.zip", "application/zip") }
    let(:resource) do
      change_set_persister.save(change_set: VectorResourceChangeSet.new(VectorResource.new, files: [file]))
    end
    let(:valid_file_set) { decorated_vector_resources.first }

    it "removes any previous error messages" do
      allow(GeoDerivatives::Processors::Vector::Info).to receive(:new).and_raise(GeoDerivatives::OgrError)
      expect { described_class.new(file_set: valid_file_set, persister: persister).characterize }.to raise_error(GeoDerivatives::OgrError)
      file_set = query_service.find_by(id: valid_file_set.id)
      expect(file_set.file_metadata[0].error_message.first).to start_with "Error during characterization:"
      allow(GeoDerivatives::Processors::Vector::Info).to receive(:new).and_call_original
      described_class.new(file_set: file_set, persister: persister).characterize
      file_set = query_service.find_by(id: valid_file_set.id)
      expect(file_set.file_metadata[0].error_message).to be_empty
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

    context "with a vector resource parent and an xml primary file" do
      let(:parent) { VectorResource.new }
      let(:file) { fixture_file_upload("files/geo_metadata/iso.xml", "application/xml") }
      it "isn't valid" do
        expect(described_class.new(file_set: valid_file_set, persister: persister).valid?).to be false
      end
    end

    context "with a vector resource parent and a geojson primary file" do
      let(:parent) { VectorResource.new }
      let(:file) { fixture_file_upload("files/vector/geo.json", "application/vnd.geo+json") }
      it "is valid" do
        expect(described_class.new(file_set: valid_file_set, persister: persister).valid?).to be true
      end
    end
  end
end
