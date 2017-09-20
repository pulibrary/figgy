# frozen_string_literal: true

require 'rails_helper'
require 'valkyrie/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe GeoCharacterizationService do
  let(:file_characterization_service) { described_class }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload('files/geo_metadata/fgdc.xml', 'application/xml') }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:map) do
    change_set_persister.save(change_set: ScannedMapChangeSet.new(ScannedMap.new, files: [file]))
  end
  let(:map_members) { query_service.find_members(resource: map) }
  let(:valid_file_set) { map_members.first }
  # Shared output context for stubbing tika
  let(:tika_output) { tika_xml_output }

  it "properly characterizes an fgdc metadata file" do
    file_node = valid_file_set
    new_file_node = described_class.new(file_node: file_node, persister: persister).characterize(save: false)
    expect(new_file_node.original_file.mime_type).to eq ["application/xml; schema=fgdc"]
  end

  describe "#valid?" do
    let(:decorator) { instance_double(FileSetDecorator, parent: parent) }

    before do
      allow(FileSetDecorator).to receive(:new).and_return(decorator)
    end

    context "with a scanned resource parent" do
      let(:parent) { ScannedResource.new }
      it "isn't valid" do
        expect(described_class.new(file_node: valid_file_set, persister: persister).valid?).to be false
      end
    end
  end
end
