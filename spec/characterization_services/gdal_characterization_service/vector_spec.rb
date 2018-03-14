# frozen_string_literal: true
require "rails_helper"
require "valkyrie/specs/shared_specs"
include ActionDispatch::TestProcess

RSpec.describe GdalCharacterizationService::Vector do
  let(:file_characterization_service) { described_class }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:vector_work) do
    change_set_persister.save(change_set: VectorWorkChangeSet.new(VectorWork.new, files: [file]))
  end
  let(:vector_work_members) { query_service.find_members(resource: vector_work) }
  let(:valid_file_set) { vector_work_members.first }

  context "with a geojson file" do
    let(:file) { fixture_file_upload("files/vector/geo.json", "application/vnd.geo+json") }
    let(:tika_output) { tika_geojson_output }

    it "sets the correct mime_type and geometry attributes on the file_node on characterize" do
      file_node = valid_file_set
      new_file_node = described_class.new(file_node: file_node, persister: persister).characterize(save: false)
      expect(new_file_node.original_file.mime_type).to eq ["application/vnd.geo+json"]
      expect(new_file_node.original_file.geometry).to eq ["Multi Polygon"]
    end
  end

  context "with a non-vector file" do
    let(:tika_output) { tika_tiff_output }

    it "sets the correct mime_type on the file_node on characterize" do
      file_node = valid_file_set
      new_file_node = described_class.new(file_node: file_node, persister: persister).characterize(save: false)
      expect(new_file_node.original_file.mime_type).to eq ["image/tiff"]
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
        expect(described_class.new(file_node: valid_file_set, persister: persister).valid?).to be false
      end
    end
  end
end
