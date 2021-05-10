# frozen_string_literal: true
require "rails_helper"

RSpec.describe GeoMetadataExtractor do
  with_queue_adapter :inline
  subject(:extractor) { described_class.new(change_set: change_set, file_node: file_set, persister: change_set_persister) }
  let(:adapter) { Valkyrie.config.metadata_adapter }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:map) do
    change_set_persister.save(change_set: ScannedMapChangeSet.new(ScannedMap.new, files: [file]))
  end
  let(:change_set) { ScannedMapChangeSet.new(map) }
  let(:map_members) { query_service.find_members(resource: map) }
  let(:file_set) { map_members.first }
  # Shared output context for stubbing tika
  let(:tika_output) { tika_xml_output }

  context "with fgdc metadata" do
    let(:file) { fixture_file_upload("files/geo_metadata/fgdc.xml", "application/xml") }

    it "extracts metadata and updates the parent resource" do
      extractor.extract
      expect(map.coverage).to eq ["northlimit=53.557926; eastlimit=135.085831; southlimit=6.318641; westlimit=73.44696; units=degrees; projection=EPSG:4326"]
      expect(map.creator).to eq ["All China Marketing Research Co., Ltd."]
      expect(map.description).to eq ["2000 and 2010 census data China, displayed at the county level."]
      expect(map.spatial).to eq ["China"]
      expect(map.temporal).to eq ["2000", "2010"]
      expect(map.title).to eq ["China census data by county, 2000-2010"]
    end
  end

  context "with iso metadata" do
    let(:file) { fixture_file_upload("files/geo_metadata/iso.xml", "application/xml") }

    it "extracts metadata and updates the parent resource" do
      extractor.extract
      expect(map.coverage).to eq ["northlimit=57.595712; eastlimit=-109.860605; southlimit=56.407644; westlimit=-112.469675; units=degrees; projection=EPSG:4326"]
      expect(map.creator).to eq ["University of Alberta"]
      expect(map.description).to include(/This raster file is the result of georeferencing/)
      expect(map.issued).to eq ["2014-09-01"]
      expect(map.publisher).to eq ["University of Alberta"]
      expect(map.spatial).to eq ["Alberta", "Western Canada", "Fort McMurray (Alta.)", "McKay (Alta.)"]
      expect(map.subject).to eq ["Society", "Imagery and Base Maps", "Biology and Ecology", "Land cover", "Land use, rural"]
      expect(map.temporal).to eq ["1914"]
      expect(map.title).to eq ["S_566_1914_clip.tif"]
    end
  end

  context "with Princeton iso metadata" do
    let(:file) { fixture_file_upload("files/geo_metadata/princeton_iso.xml", "application/xml") }

    it "extracts metadata and updates the parent resource" do
      extractor.extract
      expect(map.coverage).to eq ["northlimit=50.315241; eastlimit=-65.703868; southlimit=23.33353; westlimit=-127.875418; units=degrees; projection=EPSG:4326"]
      expect(map.creator).to eq ["Emily Leslie, Energy Reflections, LLC", "Andrew Pascale, Andlinger Center, Princeton University"]
      expect(map.description).to include(/This dataset shows the wind and solar development/)
      expect(map.issued).to eq ["2021-04-14"]
      expect(map.spatial).to eq ["United States"]
      expect(map.subject).to include("Utilities and Communication", "net-zero", "renewable energy")
      expect(map.temporal).to include("2020", "2050")
      expect(map.title).to eq ["Net-Zero America selected renewable resource projects for high-electrification scenario (base land use), 2050"]
    end
  end
end
