require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe ExternalMetadataCharacterizationService do
  let(:file_characterization_service) { described_class }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/geo_metadata/fgdc.xml", "application/xml") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:map) do
    change_set_persister.save(change_set: ScannedMapChangeSet.new(ScannedMap.new, files: [file]))
  end
  let(:map_members) { query_service.find_members(resource: map) }
  let(:valid_file_set) { map_members.first }
  # Shared output context for stubbing tika
  let(:tika_output) { tika_xml_output }

  it "characterizes a sample file" do
    described_class.new(file_set: valid_file_set, persister: persister).characterize
  end

  context "with an fgdc metadata file" do
    it "sets the file node mime_type with an fgdc mime type schema extension" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["application/xml; schema=fgdc"]
    end

    it "populates checksum and size" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      original_file = new_file_set.original_file
      fgdc_size = File.size(Rails.root.join("spec", "fixtures", "files", "geo_metadata", "fgdc.xml"))

      expect(original_file.size).to eq [fgdc_size]
      expect(original_file.checksum.first).to be_a(MultiChecksum)
    end
  end

  context "with an iso metadata file" do
    let(:file) { fixture_file_upload("files/geo_metadata/iso.xml", "application/xml") }

    it "sets the file node mime_type with an iso mime type schema extension" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["application/xml; schema=iso19139"]
    end
  end

  context "with an non-geo metadata file" do
    let(:file) { fixture_file_upload("files/geo_metadata/non-geo-metadata.xml", "application/xml") }

    it "sets the file node mime_type without a mime type extension" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["application/xml"]
    end
  end

  context "with an invalid file" do
    let(:file) { fixture_file_upload("files/geo_metadata/empty.xml", "application/xml") }

    it "sets the file node mime_type without a mime type extension" do
      file_set = valid_file_set
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["application/xml"]
    end
  end

  describe "#valid?" do
    context "with an xml primary file" do
      it "is valid" do
        expect(described_class.new(file_set: valid_file_set, persister: persister).valid?).to be true
      end
    end

    context "with a non-xml primary file" do
      let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tiff") }

      it "is not valid" do
        expect(described_class.new(file_set: valid_file_set, persister: persister).valid?).to be false
      end
    end
  end
end
