# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe GeoMetadataExtractor do
  subject(:extractor) { described_class.new(change_set: change_set, file_node: file_set, persister: persister) }
  let(:adapter) { Valkyrie.config.metadata_adapter }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:map) do
    change_set_persister.save(change_set: ScannedMapChangeSet.new(ScannedMap.new, files: [file]))
  end
  let(:change_set) { ScannedMapChangeSet.new(map) }
  let(:map_members) { query_service.find_members(resource: map) }
  let(:file_set) { map_members.first }
  # Shared output context for stubbing tika
  let(:tika_output) { tika_xml_output }

  context "with fgdc metadata" do
    let(:file) { fixture_file_upload('files/geo_metadata/fgdc.xml', 'application/xml') }

    it "extracts metadata and updates the parent resource" do
      extractor.extract
      expect(map.title).to eq ["China census data by county, 2000-2010"]
      expect(map.spatial).to eq ["China"]
      expect(map.creator).to eq ["All China Marketing Research Co., Ltd."]
      expect(map.coverage).to eq ["northlimit=53.557926; eastlimit=135.085831; southlimit=6.318641; westlimit=73.44696; units=degrees; projection=EPSG:4326"]
      expect(map.description).to eq ["2000 and 2010 census data China, displayed at the county level."]
      expect(map.temporal).to eq ["2000", "2010"]
    end
  end

  context "with iso metadata" do
    let(:file) { fixture_file_upload('files/geo_metadata/iso.xml', 'application/xml') }

    it "extracts metadata and updates the parent resource" do
      extractor.extract
      expect(map.title).to eq ["S_566_1914_clip.tif"]
      expect(map.creator).to eq ["University of Alberta"]
      expect(map.coverage).to eq ["northlimit=57.595712; eastlimit=-109.860605; southlimit=56.407644; westlimit=-112.469675; units=degrees; projection=EPSG:4326"]
    end
  end
end
