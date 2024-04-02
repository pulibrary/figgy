# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilder do
  with_queue_adapter :inline
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
  let(:scanned_resource) do
    FactoryBot.create_for_repository(
      :scanned_resource,
      title: "test title1",
      label: "test label",
      actor: "test person",
      sort_title: "test title2",
      portion_note: "test value1",
      rights_statement: RDF::URI("https://creativecommons.org/licenses/by-nc/4.0/"),
      call_number: "test value2",
      edition: "test edition",
      nav_date: "test date",
      identifier: "ark:/88435/abc1234de",
      source_metadata_identifier: "991234563506421",
      imported_metadata: [{
        description: "Test Description",
        location: ["RCPPA BL980.G7 B66 1982"]
      }],
      viewing_direction: ["right-to-left"]
    )
  end
  let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file]) }
  let(:logical_structure) do
  end
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
  let(:start_canvas) { nil }

  def logical_structure(file_set_id)
    [
      {
        "label": "Table of Contents",
        "nodes": [
          {
            "label": "Chapter 1",
            "nodes": [
              {
                "label": "Chapter 1a",
                "nodes": [
                  {
                    "proxy": file_set_id
                  }
                ]
              }
            ]
          }
        ]
      }.deep_symbolize_keys
    ]
  end

  context "when the thumbnail derivative isn't generated" do
    with_queue_adapter :test
    before do
      allow(Rails.env).to receive(:development?).and_return(false)
      allow(Rails.env).to receive(:test?).and_return(false)
      stub_catalog(bib_id: "991234563506421")
      output = change_set_persister.save(change_set: change_set)
      file_set_id = output.member_ids.first
      file_set = query_service.find_by(id: file_set_id)
      file_set.local_identifier = "p79409x97p"
      metadata_adapter.persister.save(resource: file_set)
      change_set = ScannedResourceChangeSet.new(output)
      change_set.validate(logical_structure: logical_structure(file_set_id), start_canvas: start_canvas || file_set_id)
      change_set_persister.save(change_set: change_set)
    end
    it "doesn't error" do
      output = manifest_builder.build
      expect(output["thumbnail"]).to be_blank
    end
  end

  describe "#build" do
    let(:ocr_language) { "eng" }
    before do
      stub_catalog(bib_id: "991234563506421")
      change_set.validate(ocr_language: ocr_language)
      output = change_set_persister.save(change_set: change_set)
      file_set_id = output.member_ids.first
      file_set = query_service.find_by(id: file_set_id)
      file_set.local_identifier = "p79409x97p"
      file_set.viewing_hint = ["non-paged"]
      metadata_adapter.persister.save(resource: file_set)
      change_set = ScannedResourceChangeSet.new(output)
      change_set.validate(logical_structure: logical_structure(file_set_id), start_canvas: start_canvas || file_set_id)
      change_set_persister.save(change_set: change_set)
    end

    context "when there's no ocr_language set" do
      let(:ocr_language) { nil }
      it "doesn't add a search-within service" do
        change_set

        output = manifest_builder.build
        expect(output["service"]).to eq nil
      end
    end

    it "only runs two find_by queries" do
      manifest_builder # Cache the instance which has a `find_by` to instantiate
      allow(query_service).to receive(:find_by).and_call_original

      manifest_builder.build

      # Two queries: One for thumbnail and one for start canvas
      expect(query_service).to have_received(:find_by).exactly(2).times
    end

    it "only runs one find_members query" do
      manifest_builder
      allow(query_service).to receive(:find_members).and_call_original

      manifest_builder.build

      expect(query_service).to have_received(:find_members).exactly(1).times
    end

    it "only uses cached parent info" do
      manifest_builder
      allow(query_service).to receive(:find_inverse_references_by).and_call_original

      manifest_builder.build

      expect(query_service).to have_received(:find_inverse_references_by).exactly(0).times
    end

    it "generates a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["label"]).to eq ["test title1"]
      expect(output["description"]).to eq ["Test Description"]
      expect(output["viewingHint"]).to eq "individuals"
      expect(output["viewingDirection"]).to eq "right-to-left"
      expect(output["rendering"]).to include "@id" => "http://arks.princeton.edu/ark:/88435/abc1234de", "format" => "text/html"
      expect(output["sequences"].length).to eq 1
      expect(output["sequences"][0]["rendering"][0]["@id"]).to eq "http://www.example.com/catalog/#{change_set.id}/pdf"
      expect(output["sequences"][0]["rendering"][0]["format"]).to eq "application/pdf"
      expect(output["sequences"][0]["viewingHint"]).to eq "individuals"
      canvas_id = output["sequences"][0]["canvases"][0]["@id"]
      expect(output["structures"].length).to eq 3
      expect(output["sequences"][0]["canvases"][0]["viewingHint"]).to eq "non-paged"
      structure_canvas_id = output["structures"][2]["canvases"][0]
      expect(canvas_id).to eq structure_canvas_id
      expect(output["sequences"][0]["canvases"][0]["width"]).to be_a Integer
      first_image = output["sequences"][0]["canvases"][0]["images"][0]

      expect(first_image["@id"]).to eq "http://www.example.com/concern/scanned_resources/#{scanned_resource.id}/manifest/image/#{scanned_resource.member_ids.first}"
      expect(first_image["resource"]["@id"]).to eq "http://www.example.com/image-service/#{scanned_resource.member_ids.first}/full/1000,/0/default.jpg"
      expect(output["sequences"][0]["canvases"][0]["local_identifier"]).to eq "p79409x97p"

      canvas_renderings = output["sequences"][0]["canvases"][0]["rendering"]
      expect(canvas_renderings.length).to eq 2

      canvas_rendering = canvas_renderings.first
      expect(canvas_rendering["@id"]).to eq "http://www.example.com/concern/file_sets/#{scanned_resource.member_ids.first}/text"
      expect(canvas_rendering["format"]).to eq "text/plain"
      expect(canvas_rendering["label"]).to eq "Download page text"

      canvas_rendering = canvas_renderings.last
      expect(canvas_rendering["@id"]).to eq "http://www.example.com/downloads/#{scanned_resource.member_ids.first}/file/#{scanned_resource.decorate.decorated_file_sets.first.original_file.id}"
      expect(canvas_rendering["format"]).to eq "image/tiff"
      expect(canvas_rendering["label"]).to eq "Download the original file"

      expect(first_image["data"]).to eq nil
      expect(first_image["@type"]).to eq "oa:Annotation"
      expect(first_image["motivation"]).to eq "sc:painting"
      expect(first_image["resource"]["data"]).to eq nil
      expect(first_image["resource"]["service"]["@id"]).not_to be_nil
      expect(output["thumbnail"]).not_to be_blank
      expect(output["thumbnail"]["@id"]).to eq "#{first_image['resource']['service']['@id']}/full/!200,150/0/default.jpg"
      expect(output["thumbnail"]["service"]["@id"]).to eq first_image["resource"]["service"]["@id"]
      expect(output["sequences"][0]["startCanvas"]).to eq canvas_id
      expect(output["logo"]).to eq("https://www.example.com/assets/pul_logo_icon-5333765252f2b86e34cd7c096c97e79495fe4656c5f787c5510a84ee6b67afd8.png")
      expect(output["seeAlso"].length).to eq 2
      expect(output["seeAlso"].last).to include "@id" => "https://catalog.princeton.edu/catalog/991234563506421.marcxml", "format" => "text/xml"

      expect(output["service"]["label"]).to eq "Search within this item"
    end

    context "when it's a cicognara item" do
      let(:scanned_resource) do
        FactoryBot.create_for_repository(:scanned_resource,
                                         rights_statement: RDF::URI("http://cicognara.org/microfiche_copyright"))
      end
      it "provides the vatican logo" do
        output = manifest_builder.build
        expect(output["logo"]).to eq("https://www.example.com/assets/vatican-2a0de5479c7ad0fcacf8e0bf4eccab9f963a5cfc3e0197051314c8d50969a478.png")
      end
    end

    context "when there's no derivative_file" do
      it "doesn't generate a IIIF endpoint" do
        allow_any_instance_of(FileSet).to receive(:derivative_file).and_return(nil)
        output = manifest_builder.build
        first_image = output["sequences"][0]["canvases"][0]["images"][0]
        expect(first_image["resource"]["service"]).to be_nil
      end
    end

    context "when a thumbnail_id doesn't exist" do
      let(:scanned_resource) do
        FactoryBot.create_for_repository(:scanned_resource,
                                         title: "test title1",
                                         label: "test label",
                                         actor: "test person",
                                         sort_title: "test title2",
                                         portion_note: "test value1",
                                         rights_statement: RDF::URI("https://creativecommons.org/licenses/by-nc/4.0/"),
                                         call_number: "test value2",
                                         edition: "test edition",
                                         nav_date: "test date",
                                         identifier: "ark:/88435/abc1234de",
                                         thumbnail_id: Valkyrie::ID.new("blablabla"),
                                         imported_metadata: [{
                                           description: "Test Description"
                                         }])
      end
      it "uses the first canvas as the thumbnail" do
        output = manifest_builder.build
        first_image = output["sequences"][0]["canvases"][0]["images"][0]
        expect(output["thumbnail"]).not_to be_blank
        expect(output["thumbnail"]["@id"]).to eq "#{first_image['resource']['service']['@id']}/full/!200,150/0/default.jpg"
      end
    end

    context "when a start_canvas doesn't exist" do
      let(:start_canvas) { Valkyrie::ID.new("blablabla") }
      it "doesn't set a startCanvas" do
        output = manifest_builder.build
        first_sequence = output["sequences"][0]
        expect(first_sequence["startCanvas"]).to be_nil
      end
    end

    context "when in staging" do
      it "generates pyramidal links" do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(Rails.env).to receive(:test?).and_return(false)

        output = manifest_builder.build
        expect(output["sequences"][0]["canvases"][0]["images"][0]["resource"]["service"]["@id"]).to start_with "http://localhost:8182/pyramidals/iiif/2/"
      end
    end

    it "generates a IIIF document with metadata" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output).to include "metadata"
      metadata = output["metadata"]
      expect(metadata).to be_kind_of Array
      expect(metadata.length).to eq(8)

      metadata_object = metadata.find { |h| h["label"] == "Portion Note" }
      metadata_values = metadata_object["value"]
      expect(metadata_values).to be_kind_of Array
      expect(metadata_values).to include "test value1"

      location = metadata.find { |h| h["label"] == "Location" }
      expect(location["value"]).to include "RCPPA BL980.G7 B66 1982"
    end

    context "when the resource has linked vocabulary terms" do
      subject(:manifest_builder) { described_class.new(query_service.find_by(id: ephemera_folder.id)) }

      let(:category) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Art and Culture") }
      let(:subject_term) { FactoryBot.create_for_repository(:ephemera_term, label: "Architecture", member_of_vocabulary_id: category.id) }

      let(:genres_category) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Library of Congress Genre/Form Terms") }
      let(:genre_term) { FactoryBot.create_for_repository(:ephemera_term, label: "Experimental films", member_of_vocabulary_id: genres_category.id) }
      let(:ephemera_folder) do
        FactoryBot.create_for_repository(:ephemera_folder, subject: [subject_term.id], genre: genre_term.id)
      end
      it "transforms the subject terms into JSON-LD" do
        output = manifest_builder.build
        expect(output).to be_kind_of Hash
        expect(output).to include "metadata"
        metadata = output["metadata"]
        expect(metadata).to be_kind_of Array
        expect(metadata.length).to eq(20)

        metadata_object = metadata.find { |h| h["label"] == "Subject" }
        metadata_values = metadata_object["value"]
        expect(metadata_values).to be_kind_of Array
        metadata_value = metadata_values.shift

        expect(metadata_value).to eq subject_term.label.first

        metadata_object = metadata.find { |h| h["label"] == "Genre" }
        metadata_values = metadata_object["value"]
        expect(metadata_values).to be_kind_of Array
        metadata_value = metadata_values.shift

        expect(metadata_value).to eq genre_term.label.first
      end
    end

    context "when the resource has multiple titles" do
      let(:scanned_resource) do
        FactoryBot.create_for_repository(:scanned_resource, title: ["title1", "title2"])
      end
      it "uses an array" do
        output = manifest_builder.build
        expect(output["label"]).to eq ["title1", "title2"]
      end
    end
  end

  context "when an ephemera folder has a transliterated title" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: folder.id)) }
    let(:folder) { FactoryBot.create_for_repository(:ephemera_folder, title: ["title"], transliterated_title: ["transliterated"]) }
    it "includes that in the manifest label" do
      output = manifest_builder.build
      expect(output["label"]).to eq ["title", "transliterated"]
    end
  end

  context "when given a nested child" do
    let(:scanned_resource) do
      FactoryBot.create_for_repository(:scanned_resource,
                                       member_ids: child.id,
                                       identifier: "ark:/88435/5m60qr98h",
                                       viewing_direction: "right-to-left")
    end
    let(:child) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
    it "builds a IIIF collection" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["@type"]).to eq "sc:Collection"
      expect(output["viewingHint"]).to eq "multi-part"

      expect(output["thumbnail"]).to include "@id" => "http://www.example.com/image-service/#{child.member_ids.first.id}/full/!200,150/0/default.jpg"

      expect(output["manifests"].length).to eq 1
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/scanned_resources/#{child.id}/manifest"
      expect(output["manifests"][0]["viewingHint"]).to be_nil
      expect(output["manifests"][0]["metadata"]).to be_nil
      expect(output["seeAlso"]).to include "@id" => "http://www.example.com/catalog/#{scanned_resource.id}.jsonld", "format" => "application/ld+json"
      expect(output["rendering"]).to include "@id" => "http://arks.princeton.edu/ark:/88435/5m60qr98h", "format" => "text/html"
      expect(output["license"]).to eq RightsStatements.no_known_copyright.to_s
      # not allowed in collections until iiif presentation api v3
      expect(output["viewingDirection"]).to eq nil
      expect(output["manifests"][0]["thumbnail"]["@id"]).to eq "http://www.example.com/image-service/#{child.member_ids.first}/full/!200,150/0/default.jpg"
    end
    context "when the nested child does't have a valid thumbnail" do
      let(:child) { FactoryBot.create_for_repository(:scanned_resource, thumbnail_id: ["invalid-id"]) }

      it "does not generate the thumbnail" do
        output = manifest_builder.build
        expect(output).to be_kind_of Hash
        expect(output["@type"]).to eq "sc:Collection"
        expect(output["viewingHint"]).to eq "multi-part"
        expect(output).not_to include "thumbnail"
      end
    end
  end

  context "when given a sammelband" do
    let(:scanned_resource) do
      FactoryBot.create_for_repository(:scanned_resource, files: [file])
    end
    let(:child) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }

    before do
      reloaded_resource = query_service.find_by(id: scanned_resource.id)
      change_set = ScannedResourceChangeSet.new(reloaded_resource)
      change_set.member_ids << child.id
      change_set_persister.save(change_set: change_set)
    end

    it "builds a sammelband IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["@type"]).to eq "sc:Manifest"
      expect(output["manifests"]).to eq nil
      expect(output["sequences"].first["canvases"].length).to eq 1
    end
  end

  context "when given a scanned map" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_map.id)) }
    let(:scanned_map) do
      FactoryBot.create_for_repository(:scanned_map,
                                       description: "Test Description",
                                       references: { "http://www.jstor.org/stable/1797655": ["www.jstor.org"] }.to_json,
                                       electronic_locations: ["@id": "http://arks.princeton.edu/ark:/88435/1234567"])
    end
    let(:change_set) { ScannedMapChangeSet.new(scanned_map, files: [file]) }

    before do
      output = change_set_persister.save(change_set: change_set)
      change_set = ScannedMapChangeSet.new(output)
      change_set_persister.save(change_set: change_set)
    end

    it "builds a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["description"]).to eq ["Test Description"]
      expect(output["sequences"][0]["canvases"][0]["images"].length).to eq 1
      expect(output["metadata"].find { |m| m["label"] == "Gbl Suppressed Override" }).to be nil
      expect(output["metadata"].find { |m| m["label"] == "Rendered Coverage" }).to be nil
      expect(output["metadata"].find { |m| m["label"] == "Electronic Locations" }).to be nil
      expect(output["metadata"].find { |m| m["label"] == "Rendered Links" }).to be nil
    end
  end

  context "when given a nested scanned map set" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_map.id)) }
    let(:scanned_map) do
      FactoryBot.create_for_repository(:scanned_map, description: "Test Description", member_ids: child.id)
    end
    let(:child) { FactoryBot.create_for_repository(:scanned_map, files: [file]) }
    it "builds a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["description"]).to eq ["Test Description"]
      expect(output["@type"]).to eq "sc:Manifest"
      expect(output["manifests"]).to eq nil
      expect(output["sequences"].first["canvases"].length).to eq 1
    end
  end

  context "when given a multi-volume map set" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: map_set.id)) }
    let(:map_set) do
      FactoryBot.create_for_repository(:scanned_map, description: "Test Description", member_ids: volume1.id)
    end
    let(:volume1) { FactoryBot.create_for_repository(:scanned_map, member_ids: child.id) }
    let(:child) { FactoryBot.create_for_repository(:scanned_map, files: [file]) }

    it "builds a IIIF collection" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["description"]).to eq ["Test Description"]
      expect(output["@type"]).to eq "sc:Collection"
      expect(output["viewingHint"]).to eq "multi-part"
      expect(output["manifests"].length).to eq 1
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/scanned_maps/#{volume1.id}/manifest"
      expect(output["manifests"][0]["viewingHint"]).to be_nil
      expect(output["manifests"][0]["metadata"]).to be_nil
    end
  end

  context "when given a scanned map with a raster child" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_map.id)) }
    let(:scanned_map) do
      FactoryBot.create_for_repository(:scanned_map, description: "Test Description", member_ids: child.id)
    end
    let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tiff") }
    let(:child) { FactoryBot.create_for_repository(:raster_resource, files: [file]) }
    it "builds a IIIF document without the raster child" do
      output = manifest_builder.build
      expect(output["sequences"]).to be_nil
    end
  end

  context "when given a scanned resource with an ingested JSON file" do
    let(:file) { fixture_file_upload("ingest_single_figgy_metadata/figgy_metadata.json", "") }
    before do
      stub_catalog(bib_id: "991234563506421")
    end

    it "builds a IIIF document without the JSON file", run_real_characterization: true do
      output = manifest_builder.build
      expect(output["sequences"]).to be_nil
    end
  end
  context "when given a scanned resource which was ingested with its mets file as an attached member" do
    let(:file) { fixture_file_upload("mets/pudl0001-9946125963506421.mets", "application/xml; schema=mets") }
    before do
      stub_catalog(bib_id: "991234563506421")
      # attach the file set
      output = change_set_persister.save(change_set: change_set)
      # get the correct mime_type onto the file set
      file_set_id = output.member_ids[0]
      file_set = query_service.find_by(id: file_set_id)
      file_set.original_file.mime_type = "application/xml; schema=mets"
      metadata_adapter.persister.save(resource: file_set)
    end

    it "builds a IIIF document without the mets file" do
      output = manifest_builder.build
      expect(output["sequences"]).to be_nil
    end
  end

  context "when given an ephemera project" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: ephemera_project.id)) }
    let(:ephemera_project) do
      FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, ephemera_term.id, folder2.id])
    end
    let(:ephemera_term) { FactoryBot.create_for_repository(:ephemera_term) }
    let(:box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: folder.id) }
    let(:folder) { FactoryBot.create_for_repository(:ephemera_folder) }
    let(:folder2) { FactoryBot.create_for_repository(:ephemera_folder, member_ids: folder3.id) }
    let(:folder3) { FactoryBot.create_for_repository(:ephemera_folder) }
    let(:change_set) { EphemeraProjectChangeSet.new(ephemera_project) }
    it "builds a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["metadata"]).to be_kind_of Array
      expect(output["metadata"]).not_to be_empty
      expect(output["metadata"].first).to include "label" => "Exhibit", "value" => [ephemera_project.decorate.slug]
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/ephemera_folders/#{folder.id}/manifest"
      expect(output["manifests"][1]["@id"]).to eq "http://www.example.com/concern/ephemera_folders/#{folder2.id}/manifest"
      expect(output["manifests"].length).to eq 2
    end
  end

  context "when given a scanned resource with video files" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
    let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file], downloadable: "none") }
    let(:file) { fixture_file_upload("files/city.mp4", "") }
    let(:logical_structure) { nil }
    before do
      stub_catalog(bib_id: "991234563506421")
      change_set_persister.save(change_set: change_set)
    end

    context "and the scanned resource has VTT files" do
      let(:change_set) { ChangeSet.for(query_service.find_by(id: scanned_resource.id)) }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource_with_video_and_captions) }
      it "adds a rendering for the canvas to download the caption", run_real_characterization: true, run_real_derivatives: true do
        output = manifest_builder.build
        rendering = output["items"][0]["rendering"]
        vtt_rendering = rendering.find { |x| x["format"] == "text/vtt" }
        expect(vtt_rendering["label"]).to eq "Download Caption - English (Original)"
      end
    end

    it "builds a manifest for playing video back", run_real_characterization: true, run_real_derivatives: true do
      output = manifest_builder.build
      expect(output).to include "items"
      expect(output["seeAlso"]).to be_a Array
      canvases = output["items"]
      expect(canvases.length).to eq 1
      expect(canvases.first["items"][0]["items"][0]["body"]["duration"]).to eq 5.312
      expect(canvases.first["items"][0]["items"][0]["body"]["type"]).to eq "Video"
      expect(output["structures"][0]["items"][0]["id"]).to include "#t="
    end
  end

  context "when given a collection" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: collection.id), nil, ability) }
    let(:ability) { Ability.new(user) }
    let(:user) { FactoryBot.create(:admin) }
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:change_set) { CollectionChangeSet.new(collection) }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id], member_ids: scanned_resource_2.id, thumbnail_id: scanned_resource_2.id) }
    let(:scanned_resource_2) { FactoryBot.create_for_repository(:scanned_resource) }

    before do
      scanned_resource
      output = change_set_persister.save(change_set: change_set)
      change_set = CollectionChangeSet.new(output)
      change_set_persister.save(change_set: change_set)
    end
    it "builds a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["@type"]).to eq "sc:Collection"
      expect(output["metadata"]).to be_kind_of Array
      expect(output["metadata"]).not_to be_empty
      expect(output["metadata"].first).to include "label" => "Exhibit", "value" => [collection.decorate.slug]
      expect(output["manifests"].length).to eq 1
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/scanned_resources/#{scanned_resource.id}/manifest"
      expect(output["viewingDirection"]).to eq nil
    end
    context "when given a user without access to the manifest" do
      let(:user) { FactoryBot.create(:user) }
      it "doesn't display those child manifests" do
        output = manifest_builder.build
        expect(output).to be_kind_of Hash
        expect(output["@type"]).to eq "sc:Collection"
        expect(output["metadata"]).to be_kind_of Array
        expect(output["metadata"]).not_to be_empty
        expect(output["metadata"].first).to include "label" => "Exhibit", "value" => [collection.decorate.slug]
        expect(output["manifests"].length).to eq 0
        expect(output["viewingDirection"]).to eq nil
      end
    end
  end

  context "when given a numismatic issue" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: numismatic_issue.id)) }
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:numismatic_issue) { FactoryBot.create_for_repository(:numismatic_issue) }
    let(:change_set) { Numismatics::IssueChangeSet.new(numismatic_issue, member_ids: [coin1.id, coin2.id, coin3.id]) }
    let(:coin1) { FactoryBot.create_for_repository(:coin, files: [file1]) }
    let(:coin2) { FactoryBot.create_for_repository(:coin, files: [file2]) }
    let(:coin3) { FactoryBot.create_for_repository(:coin) }
    let(:file1) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
    let(:file2) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
    before do
      numismatic_issue
      change_set_persister.save(change_set: change_set)
    end
    it "builds a IIIF document with only the coins that have images" do
      output = manifest_builder.build
      expect(output["@type"]).to eq "sc:Collection"
      expect(output["manifests"].length).to eq 2
      expect(output["manifests"][0]["label"]).to eq ["Coin: 1"]
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/numismatics/coins/#{coin1.id}/manifest"
      expect(output["manifests"][1]["label"]).to eq ["Coin: 2"]
    end
  end

  context "when given a PDF ScannedResource", run_real_characterization: true do
    let(:file) { fixture_file_upload("files/sample.pdf", "application/pdf") }
    let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file]) }
    before do
      stub_catalog(bib_id: "991234563506421")
      scanned_resource
      change_set_persister.save(change_set: change_set)
    end
    it "builds a PDF manifest of image pages" do
      output = manifest_builder.build

      expect(output["mediaSequences"]).to be_nil
      canvases = output["sequences"].first["canvases"]
      expect(canvases.length).to eq 2
    end
  end

  context "when given a legacy PDF ScannedResource" do
    it "builds a PDF mediaSequence" do
      file_set = FactoryBot.create_for_repository(
        :file_set,
        file_metadata: [
          FileMetadata.new(
            id: SecureRandom.uuid,
            mime_type: "application/pdf",
            use: Valkyrie::Vocab::PCDMUse.OriginalFile,
            file_identifiers: ["disk://bla/bla.pdf"]
          )
        ]
      )
      scanned_resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: file_set.id)

      output = described_class.new(scanned_resource).build

      media_sequence = output["mediaSequences"].first
      expect(media_sequence["@type"]).to eq "ixif:MediaSequence"
      expect(media_sequence["elements"][0]["@id"]).to eq "http://www.example.com/downloads/#{file_set.id}/file/#{file_set.original_file.id}"
      expect(media_sequence["elements"][0]["format"]).to eq "application/pdf"
      expect(media_sequence["elements"][0]["@type"]).to eq "foaf:Document"
      expect(media_sequence["elements"][0]["label"]).to eq scanned_resource.title.first
    end
  end

  context "when given a MapSet with Raster children" do
    it "adds rendering properties for the GeoTiff" do
      scanned_map = FactoryBot.create_for_repository(:scanned_map_with_raster_children)
      map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map.id])

      output = described_class.new(map_set).build

      uncropped_geo_rendering = output["sequences"][0]["canvases"][0]["rendering"].find do |rendering|
        rendering["label"] == "Download GeoTiff"
      end

      cropped_geo_rendering = output["sequences"][0]["canvases"][0]["rendering"].find do |rendering|
        rendering["label"] == "Download Cropped GeoTiff"
      end

      expect(uncropped_geo_rendering).to be_present
      expect(cropped_geo_rendering).to be_present
      uncropped_file_set = scanned_map.decorate.decorated_raster_resources.first.members.find { |x| x.service_targets.blank? }
      cropped_file_set = scanned_map.decorate.decorated_raster_resources.first.members.find { |x| x.service_targets.present? }
      expect(uncropped_geo_rendering["@id"]).to eq "http://www.example.com/downloads/#{uncropped_file_set.id}/file/#{uncropped_file_set.original_file.id}"
      expect(cropped_geo_rendering["@id"]).to eq "http://www.example.com/downloads/#{cropped_file_set.id}/file/#{cropped_file_set.original_file.id}"
    end
  end

  context "when given a ScannedMap with Raster child" do
    it "adds a rendering property for the GeoTiff" do
      scanned_map = FactoryBot.create_for_repository(:scanned_map_with_raster_child)
      output = described_class.new(scanned_map).build

      geo_rendering = output["sequences"][0]["canvases"][0]["rendering"].find do |rendering|
        rendering["label"] == "Download GeoTiff"
      end

      expect(geo_rendering).to be_present
      file_set = scanned_map.decorate.decorated_raster_resources.first.members.find { |x| x.service_targets.blank? }
      expect(geo_rendering["@id"]).to eq "http://www.example.com/downloads/#{file_set.id}/file/#{file_set.original_file.id}"
    end
  end

  context "when the structure has labels in arabic" do
    let(:structure) do
      {
        "label": "Logical",
        "nodes": [
          {
            "label": "الجزؤ العاشر من كتاب الاستيعاب",
            "nodes": [
              {
                "proxy": resource1.id
              }
            ]
          },
          {
            "label": "فائدة",
            "nodes": [
              {
                "proxy": resource2.id
              }
            ]
          }
        ]
      }
    end
    let(:imported_metadata) { [{ language: "ara" }] }
    let(:resource1) { FactoryBot.create_for_repository(:original_image_file_set) }
    let(:resource2) { FactoryBot.create_for_repository(:original_image_file_set) }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [resource1.id, resource2.id], logical_structure: structure, imported_metadata: imported_metadata) }

    # TODO: I think marc uses 3-character language codes but rdf literal
    # language tags use 2-char codes -- will UV read it anyway?
    it "sets the label as an RDF literal" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["structures"][0]["label"]).to eq("Logical")
      expect(output["structures"][1]["label"]).to eq({ "@language" => "ara", "@value" => "الجزؤ العاشر من كتاب الاستيعاب" })
      expect(output["structures"][2]["label"]).to eq({ "@language" => "ara", "@value" => "فائدة" })
    end
  end
end
