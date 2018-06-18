# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

# See https://github.com/geoblacklight/geoblacklight/wiki/Schema
describe GeoDiscovery::DocumentBuilder do
  with_queue_adapter :inline
  subject(:document_builder) { described_class.new(query_service.find_by(id: geo_work.id), document_class) }
  let(:geo_work) do
    FactoryBot.create_for_repository(:vector_resource,
                                     title: "Geo Work",
                                     coverage: coverage.to_s,
                                     description: "This is a Geo Work",
                                     creator: "Yosiwo George",
                                     publisher: "National Geographic",
                                     issued: issued,
                                     spatial: "Micronesia",
                                     temporal: "2011",
                                     subject: "Human settlements",
                                     language: "Esperanto",
                                     visibility: visibility,
                                     identifier: "ark:/99999/fk4")
  end

  let(:document_class) { GeoDiscovery::GeoblacklightDocument.new }
  let(:coverage) { GeoCoverage.new(43.039, -69.856, 42.943, -71.032) }
  let(:issued) { "01/02/2013" }
  let(:issued_xmlschema) { "2013-02-01T00:00:00Z" }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:change_set) { VectorResourceChangeSet.new(geo_work, files: [file, metadata_file]) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:file) { fixture_file_upload("files/vector/shapefile.zip") }
  let(:metadata_file) { fixture_file_upload("files/geo_metadata/iso.xml") }
  let(:document) { JSON.parse(document_builder.to_json(nil)) }

  describe "vector resource" do
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
      expect(document["dc_title_s"]).to eq("Geo Work")
      expect(document["solr_geom"]).to eq("ENVELOPE(-71.032, -69.856, 43.039, 42.943)")
      expect(document["dct_provenance_s"]).to eq("Princeton")
      expect(document["dc_rights_s"]).to eq("Public")
      expect(document["geoblacklight_version"]).to eq("1.0")

      # optional metadata
      expect(document["dc_description_s"]).to eq("This is a Geo Work")
      expect(document["dc_creator_sm"]).to eq(["Yosiwo George"])
      expect(document["dc_subject_sm"]).to eq(["Human settlements"])
      expect(document["dct_spatial_sm"]).to eq(["Micronesia"])
      expect(document["dct_temporal_sm"]).to eq(["2011"])
      expect(document["dc_language_s"]).to eq("Esperanto")
      expect(document["dc_publisher_s"]).to eq("National Geographic")

      # modified date
      expect(document["layer_modified_dt"]).to match(/\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d(Z|\+00:00)/)

      # issued date
      expect(document).to include("dct_issued_dt")
      expect(document["dct_issued_dt"]).to eq(issued_xmlschema)

      # solr year
      expect(document["solr_year_i"]).to eq(2011)

      # layer info fields
      expect(document["layer_geom_type_s"]).to eq("Mixed")
      expect(document["dc_format_s"]).to eq("Shapefile")

      # references
      refs = JSON.parse(document["dct_references_s"])
      expect(refs["http://www.isotc211.org/schemas/2005/gmd/"]).to match(/downloads/)
      expect(refs["http://schema.org/downloadUrl"]).to match(/downloads/)
      expect(refs["http://www.opengis.net/def/serviceType/ogc/wms"]).to match(/geoserver\/public-figgy\/wms/)
      expect(refs["http://www.opengis.net/def/serviceType/ogc/wfs"]).to match(/geoserver\/public-figgy\/wfs/)
      expect(refs["http://iiif.io/api/image"]).to be nil
      expect(refs["http://iiif.io/api/presentation#manifest"]).to be nil
      expect(refs["http://schema.org/url"]).to be nil
    end
  end

  describe "scanned map" do
    let(:geo_work) { FactoryBot.create_for_repository(:scanned_map, coverage: coverage.to_s, visibility: visibility) }
    let(:change_set) { ScannedMapChangeSet.new(geo_work, files: []) }

    before do
      stub_bibdata(bib_id: "5144620")
      change_set_persister.save(change_set: change_set)
    end

    context "with remote metadata" do
      let(:geo_work) do
        FactoryBot.create_for_repository(:scanned_map,
                                         source_metadata_identifier: "5144620",
                                         coverage: coverage.to_s,
                                         subject: ["Sanborn", "Mount Holly (N.J.)—Maps"],
                                         visibility: visibility,
                                         identifier: "ark:/99999/fk4",
                                         imported_metadata: [{
                                           subject: ["Mount Holly (N.J.)—Maps"],
                                           identifier: "http://arks.princeton.edu/ark:/99999/fk4"
                                         }])
      end

      it "merges and deduplicates direct and imported attributes; does not merge identifier" do
        expect(document["dc_subject_sm"]).to eq ["Mount Holly (N.J.)—Maps", "Sanborn"]
        expect(document["dc_identifier_s"]).to eq "ark:/99999/fk4"
        expect(document["layer_slug_s"]).to eq "princeton-fk4"
      end

      it "has url reference to the catalog record" do
        refs = JSON.parse(document["dct_references_s"])
        expect(refs["http://schema.org/url"]).to match(/catalog\/5144620/)
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
  end

  describe "scanned map set" do
    let(:geo_work) do
      FactoryBot.create_for_repository(:scanned_map,
                                       member_ids: child.id,
                                       coverage: coverage.to_s,
                                       visibility: visibility,
                                       identifier: "ark:/99999/fk4")
    end
    let(:child) { FactoryBot.create_for_repository(:scanned_map, coverage: coverage.to_s, visibility: visibility) }
    let(:parent_change_set) { ScannedMapChangeSet.new(geo_work, files: []) }

    before do
      change_set_persister.save(change_set: parent_change_set)
      change_set_persister.save(change_set: child_change_set)
    end

    context "with a child resouce" do
      subject(:document_builder) { described_class.new(query_service.find_by(id: child.id), document_class) }
      let(:child_change_set) { ScannedMapChangeSet.new(child, files: []) }
      it "returns a suppressed document with a source field" do
        expect(document["suppressed_b"]).to eq true
        expect(document["dct_source_sm"]).to eq ["princeton-fk4"]
      end
    end

    context "with a parent resource" do
      let(:child_change_set) { ScannedMapChangeSet.new(child, files: [file]) }
      let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }

      before do
        change_set = ScannedMapChangeSet.new(geo_work)
        change_set.validate(thumbnail_id: child.member_ids[0])
        change_set_persister.save(change_set: change_set)
      end

      it "returns an un-suppressed document with a thumbnail ref and no source field" do
        expect(document["suppressed_b"]).to be_nil
        expect(document["dct_source_sm"]).to be_nil
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
  end

  describe "raster resource" do
    let(:geo_work) { FactoryBot.create_for_repository(:raster_resource, coverage: coverage.to_s, visibility: visibility) }
    let(:change_set) { RasterResourceChangeSet.new(geo_work, files: []) }

    before do
      output = change_set_persister.save(change_set: change_set)
      file_set_id = output.member_ids[0]
      file_set = query_service.find_by(id: file_set_id)
      file_set.original_file.mime_type = "image/tiff; gdal-format=GTiff"
      metadata_adapter.persister.save(resource: file_set)
    end

    context "with a geo-tiff file" do
      let(:change_set) { RasterResourceChangeSet.new(geo_work, files: [file]) }
      let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tiff; gdal-format=GTiff") }

      it "has layer info fields" do
        expect(document["layer_geom_type_s"]).to eq("Raster")
        expect(document["dc_format_s"]).to eq("GeoTIFF")
      end
    end
  end
end
