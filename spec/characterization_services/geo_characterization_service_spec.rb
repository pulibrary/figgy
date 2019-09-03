# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe GeoCharacterizationService do
  let(:file_characterization_service) { described_class }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/geo_metadata/fgdc.xml", "application/xml") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:resource) do
    change_set_persister.save(change_set: ScannedMapChangeSet.new(ScannedMap.new, files: [file]))
  end
  let(:resource_members) { query_service.find_members(resource: resource) }
  let(:valid_file_set) { resource_members.first }
  # Shared output context for stubbing tika
  let(:tika_output) { tika_xml_output }

  it "properly characterizes an fgdc metadata file" do
    file_set = valid_file_set
    new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.mime_type).to eq ["application/xml; schema=fgdc"]
  end

  context "with a shapefile that contains documentation" do
    let(:file) { fixture_file_upload("files/vector/shapefile_with_documentation.zip", "application/zip") }
    let(:resource) do
      change_set_persister.save(change_set: VectorResourceChangeSet.new(VectorResource.new, files: [file]))
    end

    it "sets the correct mime_type on the file_set on characterize", run_real_characterization: true do
      file_set = valid_file_set
      Timeout.timeout(20) do
        new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
        expect(new_file_set.original_file.mime_type).to eq ['application/zip; ogr-format="ESRI Shapefile"']
        expect(new_file_set.original_file.geometry).to eq ["Polygon"]
      end
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
