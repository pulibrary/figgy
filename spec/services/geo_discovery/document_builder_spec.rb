# frozen_string_literal: true
require "rails_helper"

# See https://github.com/geoblacklight/geoblacklight/wiki/Schema
describe GeoDiscovery::DocumentBuilder, skip_fixity: true do
  with_queue_adapter :inline
  subject(:document_builder) { described_class.new(query_service.find_by(id: geo_work.id), document_class) }
  let(:document_class) { GeoDiscovery::GeoblacklightDocument.new }
  let(:document) { JSON.parse(document_builder.to_json(nil)) }

  let(:geo_work) do
    FactoryBot.create_for_repository(:vector_resource,
                                     coverage: coverage.to_s,
                                     issued: issued,
                                     spatial: "Micronesia",
                                     temporal: "2011",
                                     subject: ["Human settlements", "Society"],
                                     language: "Esperanto",
                                     visibility: visibility,
                                     identifier: "ark:/99999/fk4")
  end
  let(:coverage) { GeoCoverage.new(43.039, -69.856, 42.943, -71.032) }
  let(:issued) { "2013" }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:change_set) { VectorResourceChangeSet.new(geo_work, files: [file, metadata_file]) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:file) { fixture_file_upload("files/vector/shapefile.zip") }
  let(:metadata_file) { fixture_file_upload("files/geo_metadata/iso.xml") }

  describe "vector resource", run_real_characterization: true do
    before do
      output = change_set_persister.save(change_set: change_set)
      file_set_id = output.member_ids[0]
      file_set = query_service.find_by(id: file_set_id)
      file_set.original_file.mime_type = 'application/zip; ogr-format="ESRI Shapefile"'
      metadata_adapter.persister.save(resource: file_set)
      metadata_file_set_id = output.member_ids[1]
      metadata_file_set = query_service.find_by(id: metadata_file_set_id)
      metadata_file_set.original_file.mime_type = "application/xml; schema=iso19139"
      metadata_adapter.persister.save(resource: metadata_file_set)
    end

    it "has metadata" do
      # required metadata
      expect(document["dc_identifier_s"]).to eq("ark:/99999/fk4")
      expect(document["layer_slug_s"]).to eq("princeton-fk4")
      expect(document["dc_title_s"]).to eq("S_566_1914_clip.tif")
      expect(document["solr_geom"]).to eq("ENVELOPE(-112.469675, -109.860605, 57.595712, 56.407644)")
      expect(document["dct_provenance_s"]).to eq("Princeton")
      expect(document["dc_rights_s"]).to eq("Public")
      expect(document["geoblacklight_version"]).to eq("1.0")

      # optional metadata
      expect(document["dc_description_s"]).to include("This raster file is the result of georeferencing")
      expect(document["dc_creator_sm"]).to eq(["University of Alberta"])
      expect(document["dc_subject_sm"]).to eq(["Society", "Imagery and Base Maps", "Biology and Ecology"])
      expect(document["all_subject_sm"]).to eq(["Society", "Imagery and Base Maps", "Biology and Ecology", "Land cover", "Land use, rural"])
      expect(document["dct_spatial_sm"]).to eq(["Alberta", "Western Canada", "Fort McMurray (Alta.)", "McKay (Alta.)"])
      expect(document["dct_temporal_sm"]).to eq(["1914", "2014-09-01"])
      expect(document["dc_language_s"]).to eq("Esperanto")
      expect(document["dc_publisher_s"]).to eq("University of Alberta")

      # modified date
      expect(document["layer_modified_dt"]).to match(/\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d(Z|\+00:00)/)

      # issued date
      expect(document).to include("dct_issued_dt")
      expect(document["dct_issued_dt"]).to eq("2014-09-01T00:00:00Z")

      # solr year
      expect(document["solr_year_i"]).to eq(1914)

      # layer info fields
      expect(document["layer_geom_type_s"]).to eq("Polygon")
      expect(document["dc_format_s"]).to eq("Shapefile")

      # references
      refs = JSON.parse(document["dct_references_s"])
      expect(refs["http://www.isotc211.org/schemas/2005/gmd/"]).to match(/downloads/)
      expect(refs["http://schema.org/downloadUrl"]).to match(/downloads/)
      expect(refs["http://www.opengis.net/def/serviceType/ogc/wms"]).to match(/geoserver\/public-figgy\/wms/)
      expect(refs["http://www.opengis.net/def/serviceType/ogc/wfs"]).to match(/geoserver\/public-figgy\/wfs/)
      expect(refs["http://www.opengis.net/def/serviceType/ogc/wmts"]).to be nil # only exists for rasters and raster sets
      expect(refs["http://iiif.io/api/image"]).to be nil
      expect(refs["http://iiif.io/api/presentation#manifest"]).to be nil
      expect(refs["http://schema.org/url"]).to be nil
    end
  end

  describe "scanned map" do
    let(:geo_work) { FactoryBot.create_for_repository(:scanned_map, coverage: coverage.to_s, visibility: visibility, issued: issued) }
    let(:change_set) { ScannedMapChangeSet.new(geo_work, files: []) }

    before do
      stub_bibdata(bib_id: "5144620")
      change_set_persister.save(change_set: change_set)
    end

    context "with remote metadata" do
      let(:issued) { "2013" }
      let(:geo_work) do
        FactoryBot.create_for_repository(
          :scanned_map,
          title: [],
          source_metadata_identifier: "5144620",
          coverage: coverage.to_s,
          subject: ["Sanborn", "Mount Holly (N.J.)—Maps"],
          visibility: visibility,
          identifier: "ark:/99999/fk4",
          portion_note: "Sheet 1",
          imported_metadata: [{
            title: ["Mount Holly, N.J."],
            subject: ["Mount Holly (N.J.)—Maps"],
            identifier: "http://arks.princeton.edu/ark:/99999/fk4",
            call_number: [
              "HMC04 (Mount Holly)",
              "Electronic Resource"
            ]
          }]
        )
      end

      it "merges and deduplicates direct and imported attributes; does not merge identifier" do
        expect(document["dc_subject_sm"]).to eq ["Mount Holly (N.J.)—Maps", "Sanborn"]
        expect(document["dc_identifier_s"]).to eq "ark:/99999/fk4"
        expect(document["layer_slug_s"]).to eq "princeton-fk4"
        expect(document["dc_title_s"]).to eq "Mount Holly, N.J. (Sheet 1)"
      end

      it "has url reference to the catalog record and a call number field" do
        refs = JSON.parse(document["dct_references_s"])
        expect(refs["http://schema.org/url"]).to match(/catalog\/5144620/)
        expect(document["call_number_s"]).to eq("HMC04 (Mount Holly)")
      end

      it "sets date to created date if not defined in imported metadata" do
        expect(document["solr_year_i"]).to eq(Date.current.year)
      end
    end

    context "with imported date" do
      let(:geo_work) do
        FactoryBot.create_for_repository(
          :scanned_map,
          source_metadata_identifier: "5144620",
          coverage: coverage.to_s,
          visibility: visibility,
          imported_metadata: [{
            date: ["1884"]
          }]
        )
      end

      it "sets solr year using the date value" do
        expect(document["solr_year_i"]).to eq(1884)
      end
    end

    context "with no description" do
      it "uses a default description" do
        expect(document["dc_description_s"]).to eq("A scanned map object.")
      end
    end

    context "with a tiff file" do
      let(:change_set) { ScannedMapChangeSet.new(geo_work, files: [file]) }
      let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }

      it "has correct references" do
        refs = JSON.parse(document["dct_references_s"])
        expect(refs["http://schema.org/thumbnailUrl"]).to match(/downloads/)
        expect(refs["http://iiif.io/api/image"]).to match(/image-service/)
        expect(refs["http://iiif.io/api/presentation#manifest"]).to match(/concern\/scanned_maps/)
        expect(refs["http://iiif.io/api/image"]).to match(/image-service/)
        expect(refs["http://www.opengis.net/def/serviceType/ogc/wms"]).to be nil
        expect(refs["http://www.opengis.net/def/serviceType/ogc/wfs"]).to be nil
        expect(refs["http://www.opengis.net/def/serviceType/ogc/wmts"]).to be nil
      end

      it "has layer info fields" do
        expect(document["layer_geom_type_s"]).to eq("Image")
        expect(document["dc_format_s"]).to eq("TIFF")
      end
    end

    context "with an authenticated visibility" do
      let(:change_set) { ScannedMapChangeSet.new(geo_work, files: [file]) }
      let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }

      it "returns a document with reduced references and restricted access" do
        refs = JSON.parse(document["dct_references_s"])
        expect(refs).to have_key "http://schema.org/thumbnailUrl"
        expect(refs).not_to have_key "http://schema.org/downloadUrl"
        expect(refs).not_to have_key "http://iiif.io/api/image"
        expect(refs).not_to have_key "http://www.opengis.net/def/serviceType/ogc/wmts"
        expect(document["dc_rights_s"]).to eq "Restricted"
      end
    end

    context "with a private visibility" do
      let(:change_set) { ScannedMapChangeSet.new(geo_work, files: [file]) }
      let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

      it "returns a document with reduced references and restricted access" do
        refs = JSON.parse(document["dct_references_s"])
        expect(refs).to have_key "http://schema.org/thumbnailUrl"
        expect(refs).not_to have_key "http://schema.org/downloadUrl"
        expect(refs).not_to have_key "http://iiif.io/api/image"
        expect(refs).not_to have_key "http://www.opengis.net/def/serviceType/ogc/wmts"
        expect(document["dc_rights_s"]).to eq "Restricted"
      end
    end

    context "with a public visibility and a missing required metadata field" do
      let(:coverage) { nil }

      it "returns an error document" do
        expect(document["error"][0]).to include("solr_geom")
        expect(document["error"].size).to eq(1)
        expect(document_builder.to_hash[:error].size).to eq(1)
      end
    end

    context "with a private visibility and a missing required metadata field" do
      let(:coverage) { nil }
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

      it "returns an error document" do
        expect(document["error"][0]).to include("solr_geom")
        expect(document["error"].size).to eq(1)
        expect(document_builder.to_hash[:error].size).to eq(1)
      end
    end

    context "with an issue date string with non-numeric text" do
      let(:issued) { "Published in New Orleans, 2013-14" }

      it "does not return an issued value" do
        expect(document).not_to include("dct_issued_dt")
      end
    end

    context "with a valid coverage and an invalid imported coverge" do
      let(:invalid_coverage) { "northlimit=15.744444; eastlimit=088.566667; southlimit=15.675000; westlimit=088.627778; units=degrees; projection=EPSG:4326" }
      let(:geo_work) do
        FactoryBot.create_for_repository(
          :scanned_map,
          source_metadata_identifier: "5144620",
          coverage: coverage.to_s,
          visibility: visibility,
          imported_metadata: [{
            coverage: [invalid_coverage]
          }]
        )
      end

      it "sets solr_geom using the valid coverage value" do
        expect(document["solr_geom"]).to eq("ENVELOPE(-71.032, -69.856, 43.039, 42.943)")
      end
    end
  end

  describe "scanned map set" do
    let(:geo_work) do
      FactoryBot.create_for_repository(
        :scanned_map,
        member_ids: child.id,
        coverage: coverage.to_s,
        visibility: visibility,
        identifier: "ark:/99999/fk4"
      )
    end
    let(:child) { FactoryBot.create_for_repository(:scanned_map, coverage: coverage.to_s, visibility: visibility, gbl_suppressed_override: "0") }
    let(:parent_change_set) { ScannedMapChangeSet.new(geo_work, files: []) }

    before do
      change_set_persister.save(change_set: parent_change_set)
      change_set_persister.save(change_set: child_change_set)
    end

    context "when it is a child resouce" do
      subject(:document_builder) { described_class.new(query_service.find_by(id: child.id), document_class) }
      let(:child_change_set) { ScannedMapChangeSet.new(child, files: []) }
      it "returns a suppressed document with a source field" do
        expect(document["suppressed_b"]).to eq true
        expect(document["dc_source_sm"]).to eq ["princeton-fk4"]
      end
    end

    context "when it is a child resouce and gbl_suppressed_override is true" do
      subject(:document_builder) { described_class.new(query_service.find_by(id: child.id), document_class) }
      let(:child) { FactoryBot.create_for_repository(:scanned_map, coverage: coverage.to_s, visibility: visibility, gbl_suppressed_override: "1") }
      let(:child_change_set) { ScannedMapChangeSet.new(child, files: []) }
      it "returns a non-suppressed document" do
        expect(document["suppressed_b"]).to be false
      end
    end

    context "when it is a parent resource" do
      let(:child_change_set) { ScannedMapChangeSet.new(child, files: [file]) }
      let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }

      before do
        change_set = ScannedMapChangeSet.new(geo_work)
        change_set.validate(thumbnail_id: child.id)
        change_set_persister.save(change_set: change_set)
      end

      it "returns an un-suppressed document with a thumbnail ref and no source field" do
        expect(document["suppressed_b"]).to be false
        expect(document["dc_source_sm"]).to be_nil
      end

      it "returns document with thumbnail and iiif refs" do
        refs = JSON.parse(document["dct_references_s"])
        expect(refs["http://schema.org/thumbnailUrl"]).to match(/downloads/)
        expect(refs["http://iiif.io/api/presentation#manifest"]).to match(/concern\/scanned_maps/)
        expect(refs["http://iiif.io/api/image"]).to match(/image-service/)
      end
    end

    context "with a parent resource that is missing its thumbnail file set" do
      let(:geo_work) do
        FactoryBot.create_for_repository(:scanned_map,
                                         member_ids: child.id,
                                         thumbnail_id: missing_id,
                                         coverage: coverage.to_s,
                                         visibility: visibility)
      end
      let(:missing_id) { Valkyrie::ID.new("missing") }
      let(:child_change_set) { ScannedMapChangeSet.new(child, files: [file]) }
      let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }

      it "returns document with no thumbnail or iiif refs" do
        refs = JSON.parse(document["dct_references_s"])
        expect(refs["http://schema.org/thumbnailUrl"]).to be_nil
        expect(refs["http://iiif.io/api/presentation#manifest"]).to be_nil
      end
    end

    context "when it has a raster resource member" do
      let(:geo_work) do
        FactoryBot.create_for_repository(
          :scanned_map,
          member_ids: child.id,
          coverage: coverage.to_s,
          visibility: visibility
        )
      end
      let(:child) do
        FactoryBot.create_for_repository(
          :raster_resource,
          coverage: coverage.to_s,
          files: [file]
        )
      end
      let(:child_change_set) { ChangeSet.for(child) }
      let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tiff; gdal-format=GTiff") }

      before do
        file_set_id = child.member_ids[0]
        file_set = query_service.find_by(id: file_set_id)
        file_set.original_file.mime_type = "image/tiff; gdal-format=GTiff"
        file_set.service_targets = ["mosaic"]
        metadata_adapter.persister.save(resource: file_set)
      end

      it "returns document wmts reference" do
        refs = JSON.parse(document["dct_references_s"])
        expect(refs["http://www.opengis.net/def/serviceType/ogc/wmts"]).to match(/WMTSCapabilities/)
      end
    end
  end

  describe "raster resource" do
    let(:geo_work) do
      FactoryBot.create_for_repository(:raster_resource,
                                       coverage: coverage.to_s,
                                       subject: ["Human settlements", "Society"],
                                       visibility: visibility)
    end
    let(:change_set) { RasterResourceChangeSet.new(geo_work, files: [file]) }
    let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tiff; gdal-format=GTiff") }

    before do
      output = change_set_persister.save(change_set: change_set)
      file_set_id = output.member_ids[0]
      file_set = query_service.find_by(id: file_set_id)
      file_set.original_file.mime_type = "image/tiff; gdal-format=GTiff"
      metadata_adapter.persister.save(resource: file_set)
    end

    it "has metadata" do
      # Layer info fields
      expect(document["layer_geom_type_s"]).to eq("Raster")
      expect(document["dc_format_s"]).to eq("GeoTIFF")
      expect(document["all_subject_sm"]).to eq(["Human settlements", "Society"])

      # References
      refs = JSON.parse(document["dct_references_s"])
      expect(refs["http://www.opengis.net/def/serviceType/ogc/wms"]).to match(/geoserver\/public-figgy\/wms/)
      expect(refs["http://www.opengis.net/def/serviceType/ogc/wcs"]).to match(/geoserver\/public-figgy\/wcs/)
      expect(refs["http://www.opengis.net/def/serviceType/ogc/wmts"]).to match(/WMTSCapabilities/)
      expect(refs["https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames"]).to match(/tiles/)
      expect(refs["http://www.opengis.net/def/serviceType/ogc/wfs"]).to be_nil

      # Subjects filtered by FGDC topics
      expect(document["dc_subject_sm"]).to eq(["Society"])
    end

    context "with a non-Princeton value in the held_by property" do
      let(:geo_work) do
        FactoryBot.create_for_repository(:raster_resource,
                                         coverage: coverage.to_s,
                                         visibility: visibility,
                                         identifier: "ark:/99999/fk4",
                                         held_by: "Other Institution")
      end

      it "references the value in identifier fields" do
        expect(document["dct_provenance_s"]).to eq("Other Institution")
        expect(document["layer_slug_s"]).to eq("other-institution-fk4")
        expect(document["uuid"]).to eq "other-institution-fk4"
      end
    end
  end

  describe "raster set" do
    context "with an open raster set" do
      let(:geo_work) do
        FactoryBot.create_for_repository(
          :raster_set,
          coverage: coverage.to_s
        )
      end

      it "has wmts and xyz references" do
        geo_work
        id = geo_work.id.to_s.delete("-")
        refs = JSON.parse(document["dct_references_s"])
        expect(refs["http://www.opengis.net/def/serviceType/ogc/wmts"]).to eq "https://map-tiles-test.example.com/mosaicjson/WMTSCapabilities.xml?id=#{id}"
        expect(refs["https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames"]).to eq "https://map-tiles-test.example.com/mosaicjson/tiles/WebMercatorQuad/{z}/{x}/{y}@1x.png?id=#{id}"
      end
    end

    context "with an authenticated raster set" do
      let(:geo_work) do
        FactoryBot.create_for_repository(
          :raster_set,
          coverage: coverage.to_s,
          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        )
      end

      it "does not have wmts and xyz references" do
        geo_work
        refs = JSON.parse(document["dct_references_s"])
        expect(refs["http://www.opengis.net/def/serviceType/ogc/wmts"]).to be_nil
        expect(refs["https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames"]).to be_nil
      end
    end
  end
end
