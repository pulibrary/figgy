require "rails_helper"

describe GeoDiscovery::GeoblacklightAardvarkDocument, skip_fixity: true do
  with_queue_adapter :inline
  subject(:document_builder) { GeoDiscovery::DocumentBuilder.new(query_service.find_by(id: geo_work.id), document_class) }
  let(:document_class) { described_class.new }
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

  before do
    allow(MosaicJob).to receive(:perform_later)
  end

  describe "vector resource", run_real_characterization: true do
    before do
      output = change_set_persister.save(change_set: change_set)
      file_set_id = output.member_ids[0]
      file_set = query_service.find_by(id: file_set_id)
      file_set.primary_file.mime_type = 'application/zip; ogr-format="ESRI Shapefile"'
      metadata_adapter.persister.save(resource: file_set)
      metadata_file_set_id = output.member_ids[1]
      metadata_file_set = query_service.find_by(id: metadata_file_set_id)
      metadata_file_set.primary_file.mime_type = "application/xml; schema=iso19139"
      metadata_adapter.persister.save(resource: metadata_file_set)
    end

    it "has required Aardvark metadata" do
      expect(document["id"]).to eq("princeton-fk4")
      expect(document["dct_title_s"]).to eq("S_566_1914_clip.tif")
      expect(document["gbl_resourceClass_sm"]).to eq(["Datasets"])
      expect(document["dct_accessRights_s"]).to eq("Public")
      expect(document["gbl_mdVersion_s"]).to eq("Aardvark")
    end

    it "has optional Aardvark metadata" do
      expect(document["dct_description_sm"]).to be_an(Array)
      expect(document["dct_description_sm"].first).to include("This raster file is the result of georeferencing")
      expect(document["dct_creator_sm"]).to eq(["University of Alberta"])
      expect(document["dct_language_sm"]).to include("Esperanto")
      expect(document["dct_publisher_sm"]).to include("University of Alberta")
      expect(document["dct_subject_sm"]).to eq(["Society", "Imagery and Base Maps", "Biology and Ecology", "Land cover", "Land use, rural"])
      expect(document["dcat_theme_sm"]).to eq(["Society", "Imagery and Base Maps", "Biology and Ecology"])
      expect(document["dct_spatial_sm"]).to eq(["Alberta", "Western Canada", "Fort McMurray (Alta.)", "McKay (Alta.)"])
      expect(document["dct_temporal_sm"]).to eq(["1914", "2014-09-01"])
    end

    it "has date and year fields" do
      expect(document["gbl_mdModified_dt"]).to match(/\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d(Z|\+00:00)/)
      expect(document["gbl_indexYear_im"]).to eq([1914])
      expect(document["dct_issued_s"]).to eq("2014")
    end

    it "has layer info and format fields" do
      expect(document["gbl_resourceType_sm"]).to eq(["Polygon"])
      expect(document["dct_format_s"]).to eq("Shapefile")
    end

    it "has spatial coverage fields" do
      expect(document["locn_geometry"]).to eq("ENVELOPE(-112.469675, -109.860605, 57.595712, 56.407644)")
      expect(document["dcat_bbox"]).to eq("ENVELOPE(-112.469675, -109.860605, 57.595712, 56.407644)")
    end

    it "has identifier and provider fields" do
      expect(document["dct_identifier_sm"]).to eq(["ark:/99999/fk4"])
      expect(document["schema_provider_s"]).to eq("Princeton")
    end

    it "has references" do
      refs = JSON.parse(document["dct_references_s"])
      expect(refs["http://www.isotc211.org/schemas/2005/gmd/"]).to match(/downloads/)
      expect(refs["http://schema.org/downloadUrl"]).to match(/downloads/)
      expect(refs["https://github.com/protomaps/PMTiles"]).to match(/display_vector.pmtiles/)
      expect(refs["http://www.opengis.net/def/serviceType/ogc/wmts"]).to be_nil
      expect(refs["http://iiif.io/api/image"]).to be_nil
      expect(refs["http://iiif.io/api/presentation#manifest"]).to be_nil
    end

    it "has rights statement" do
      expect(document["rights_statement_s"]).to eq geo_work.decorate.rendered_rights_statement.first
    end
  end

  describe "scanned map" do
    let(:geo_work) { FactoryBot.create_for_repository(:scanned_map, coverage: coverage.to_s, visibility: visibility, issued: issued) }
    let(:change_set) { ScannedMapChangeSet.new(geo_work, files: []) }

    before do
      stub_catalog(bib_id: "9951446203506421")
      change_set_persister.save(change_set: change_set)
    end

    context "with a tiff file" do
      let(:change_set) { ScannedMapChangeSet.new(geo_work, files: [file]) }
      let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }

      it "has Image resource class and type" do
        expect(document["gbl_resourceClass_sm"]).to eq(["Maps"])
        expect(document["gbl_resourceType_sm"]).to eq(["Image"])
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
        expect(document["dct_accessRights_s"]).to eq "Restricted"
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
        expect(document["dct_accessRights_s"]).to eq "Restricted"
      end
    end

    context "with missing coverage" do
      let(:coverage) { nil }

      it "returns an error document" do
        expect(document["error"][0]).to include("locn_geometry")
        expect(document["error"].size).to eq(1)
        expect(document_builder.to_hash[:error].size).to eq(1)
      end
    end

    context "with an issue date string with non-numeric text" do
      let(:issued) { "Published in New Orleans, 2013-14" }

      it "does not return a dct_issued_s value" do
        expect(document).not_to include("dct_issued_s")
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

    context "when it is a child resource" do
      subject(:document_builder) { GeoDiscovery::DocumentBuilder.new(query_service.find_by(id: child.id), document_class) }
      let(:child_change_set) { ScannedMapChangeSet.new(child, files: []) }

      it "returns a suppressed document with a source field" do
        expect(document["gbl_suppressed_b"]).to eq true
        expect(document["dct_source_sm"]).to eq ["princeton-fk4"]
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
      let(:child_change_set) do
        reloaded_resource = query_service.find_by(id: child.id)
        ChangeSet.for(reloaded_resource)
      end
      let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tiff; gdal-format=GTiff") }

      before do
        file_set_id = child.member_ids[0]
        file_set = query_service.find_by(id: file_set_id)
        file_set.primary_file.mime_type = "image/tiff; gdal-format=GTiff"
        file_set.service_targets = ["tiles"]
        metadata_adapter.persister.save(resource: file_set)
      end

      it "returns document with both Maps and Datasets resource classes" do
        expect(document["gbl_resourceClass_sm"]).to contain_exactly("Maps", "Datasets")
        expect(document["gbl_resourceType_sm"]).to contain_exactly("Image", "Raster")
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
      file_set.primary_file.mime_type = "image/tiff; gdal-format=GTiff"
      file_set.service_targets = ["tiles"]
      metadata_adapter.persister.save(resource: file_set)
    end

    it "has Datasets resource class and Raster type" do
      expect(document["gbl_resourceClass_sm"]).to eq(["Datasets"])
      expect(document["gbl_resourceType_sm"]).to eq(["Raster"])
      expect(document["dct_format_s"]).to eq("GeoTIFF")
    end

    it "has all subjects and filtered theme" do
      expect(document["dct_subject_sm"]).to eq(["Human settlements", "Society"])
      expect(document["dcat_theme_sm"]).to eq(["Society"])
    end
  end
end
