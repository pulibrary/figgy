# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilder do
  with_queue_adapter :inline
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
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
                                     source_metadata_identifier: "123456",
                                     imported_metadata: [{
                                       description: "Test Description",
                                       location: ["RCPPA BL980.G7 B66 1982"]
                                     }],
                                     viewing_direction: ["right-to-left"])
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
      stub_bibdata(bib_id: "123456")
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
      stub_bibdata(bib_id: "123456")
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

    it "generates a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["label"]).to eq ["test title1"]
      expect(output["description"]).to eq ["Test Description"]
      expect(output["viewingHint"]).to eq "individuals"
      expect(output["viewingDirection"]).to eq "right-to-left"
      expect(output["rendering"]).to include "@id" => "http://arks.princeton.edu/ark:/88435/abc1234de", "format" => "text/html"
      expect(output["sequences"].length).to eq 1
      expect(output["sequences"][0]["rendering"][0]["@id"]).to eq "http://www.example.com/concern/scanned_resources/#{change_set.id}/pdf"
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
      expect(output["logo"]).to eq("https://www.example.com/assets/pul_logo_icon-7b5f9384dfa5ca04f4851c6ee9e44e2d6953e55f893472a3e205e1591d3b2ca6.png")
      expect(output["seeAlso"].length).to eq 2
      expect(output["seeAlso"].last).to include "@id" => "https://bibdata.princeton.edu/bibliographic/123456", "format" => "text/xml"

      expect(output["service"]["label"]).to eq "Search within this item"
    end

    context "when it's a cicognara item" do
      let(:scanned_resource) do
        FactoryBot.create_for_repository(:scanned_resource,
                                         rights_statement: RDF::URI("http://cicognara.org/microfiche_copyright"))
      end
      it "provides the vatican logo" do
        output = manifest_builder.build
        expect(output["logo"]).to eq("https://www.example.com/assets/vatican-f101dc8edbdd7cfb0b0152c2d2304e805c215cbff0e7ac25fb72dbfd1c568bfc.png")
      end
    end

    context "when it is a Playlist" do
      subject(:manifest_builder) { described_class.new(query_service.find_by(id: resource.id)) }

      let(:resource) do
        FactoryBot.create_for_repository(:playlist)
      end
      let(:output) do
        manifest_builder.build
      end
      it "generates the Manifest" do
        expect(output).not_to be_empty
        expect(output).to include("label" => resource.title)
      end

      context "with proxies to FileSets", run_real_characterization: true do
        with_queue_adapter :inline

        let(:tika_output) { tika_wav_output }

        let(:file1) { fixture_file_upload("files/audio_file.wav") }
        let(:file2) { fixture_file_upload("av/la_demo_bag/data/32101047382484_1_pm.wav") }
        let(:file3) { fixture_file_upload("av/la_demo_bag/data/32101047382484_1_pm.wav") }
        let(:recording) { FactoryBot.create_for_repository(:recording, files: [file1, file2, file3]) }
        let(:file_set1) do
          recording.decorate.decorated_file_sets.first
        end
        let(:file_set2) do
          recording.decorate.decorated_file_sets.to_a[1]
        end
        let(:file_set3) do
          recording.decorate.decorated_file_sets.last
        end
        let(:proxy1) do
          res = ProxyFileSet.new(proxied_file_id: file_set1.id, label: "Proxy Title")
          cs = ProxyFileSetChangeSet.new(res)
          change_set_persister.save(change_set: cs)
        end
        let(:proxy2) do
          res = ProxyFileSet.new(proxied_file_id: file_set2.id, label: "Proxy Title2")
          cs = ProxyFileSetChangeSet.new(res)
          change_set_persister.save(change_set: cs)
        end
        let(:proxy3) do
          res = ProxyFileSet.new(proxied_file_id: file_set3.id, label: "Proxy Title3")
          cs = ProxyFileSetChangeSet.new(res)
          change_set_persister.save(change_set: cs)
        end
        let(:resource) do
          FactoryBot.create_for_repository(
            :playlist,
            member_ids: [proxy1.id, proxy2.id, proxy3.id],
            logical_structure: [
              { label: "Test",
                nodes: [
                  { label: "Chapter 1", nodes:
                    [
                      { proxy: proxy1.id },
                      { label: "Chapter 1a", nodes:
                        [
                          { proxy: proxy2.id }
                        ] },
                      {
                        proxy: proxy3.id
                      }
                    ] }
                ] }
            ]
          )
        end

        it "generates the Canvases for the FileSets" do
          expect(output).not_to be_empty

          expect(output).to include("rendering")
          expect(output["rendering"]).to be_empty

          expect(output).to include("items")
          expect(output["items"].length).to eq(3)

          first_canvas = output["items"].first
          expect(first_canvas["label"]["@none"]).to eq ["Proxy Title"]

          expect(first_canvas).to include("items")
          expect(first_canvas["items"].length).to eq(1)
          anno_page = first_canvas["items"].first
          expect(anno_page).to include("items")
          expect(anno_page["items"].length).to eq(1)
          first_annotation = anno_page["items"].first
          expect(first_annotation).to include("body")
          expect(first_annotation["body"]).to include("format" => "application/vnd.apple.mpegurl")

          last_canvas = output["items"].last
          expect(last_canvas).to include("items")
          expect(last_canvas["items"].length).to eq(1)
          anno_page = last_canvas["items"].first
          expect(anno_page).to include("items")
          expect(anno_page["items"].length).to eq(1)
          last_annotation = anno_page["items"].first
          expect(last_annotation).to include("body")
          expect(last_annotation["body"]).to include("format" => "application/vnd.apple.mpegurl")

          expect(output["structures"][0]["items"][0]["label"]).to eq("@none" => ["Proxy Title"])
          expect(output["structures"][0]["items"][0]["items"][0]["id"].split("#").first).to eq first_canvas["id"]
          expect(output["structures"][0]["items"][1]["items"][0]["label"]).to eq("@none" => ["Proxy Title2"])
          expect(output["structures"][0]["items"][2]["label"]).to eq("@none" => ["Proxy Title3"])
        end

        context "when an authorization token is used to access the Playlist Manifest" do
          subject(:manifest_builder) { described_class.new(persisted, persisted.auth_token) }

          let(:persisted) do
            change_set = PlaylistChangeSet.new(resource)
            change_set.validate(state: ["complete"])
            change_set_persister.save(change_set: change_set)
          end

          it "generates links with the auth. token" do
            expect(output).not_to be_empty
            expect(output).to include("items")
            expect(output["items"].length).to eq(3)

            first_canvas = output["items"].first
            first_annotation_page = first_canvas["items"].first
            first_annotation = first_annotation_page["items"].first
            file_node1 = file_set1.file_metadata.select(&:derivative?).first
            expect(first_annotation["body"]).to include("id" => "http://www.example.com/downloads/#{file_set1.id}/file/#{file_node1.id}?auth_token=#{persisted.auth_token}")
          end
        end

        context "when the derivative cannot be retrieved for the FileSet" do
          before do
            allow_any_instance_of(FileSet).to receive(:derivative_file).and_return(nil)
          end
          it "generates the Canvases for the FileSets" do
            expect(output).not_to be_empty

            first_canvas = output["items"].first
            first_annotation_page = first_canvas["items"].first
            first_annotation = first_annotation_page["items"].first
            expect(first_annotation["body"]["id"]).to be nil

            last_canvas = output["items"].last
            first_annotation_page = last_canvas["items"].first
            first_annotation = first_annotation_page["items"].first
            expect(first_annotation["body"]["id"]).to be nil
          end
        end

        context "when the recording has FileSets for the XML metadata file, an image file, and two audio files", run_real_derivatives: true do
          with_queue_adapter :inline
          subject(:manifest_builder) { described_class.new(recording) }

          let(:file1) { fixture_file_upload("files/audio_file.wav") }
          let(:file2) { fixture_file_upload("files/example.tif") }
          let(:recording) { FactoryBot.create_for_repository(:recording, files: [file1, file2]) }
          let(:file_set1) do
            recording.decorate.decorated_file_sets.first
          end
          let(:file_set2) do
            recording.decorate.decorated_file_sets.last
          end

          it "render the image as a background file" do
            manifest_builder
            output = manifest_builder.build

            expect(output).not_to be_empty
            expect(output).to include("items")
            items = output["items"]
            expect(items.length).to eq(1)

            audio_canvas = items.first
            pages = audio_canvas["items"]
            expect(pages.length).to eq(1)

            annotations = pages.first["items"]
            expect(annotations.length).to eq(1)

            body = annotations.last["body"]
            expect(body["label"]).to eq("@none" => ["audio_file.wav"])

            expect(output).to include("posterCanvas")
            poster_canvas = output["posterCanvas"]

            pages = poster_canvas["items"]
            expect(pages.length).to eq(1)

            annotations = pages.first["items"]
            expect(annotations.length).to eq(1)

            body = annotations.last["body"]
            expect(body["type"]).to eq("Image")
            expect(body["height"]).to eq(287)
            expect(body["width"]).to eq(200)
            expect(body["format"]).to eq("image/jpeg")
          end
        end
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
      it "generates pyramidal cantaloupe links" do
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
      expect(metadata.length).to eq(7)

      metadata_object = metadata.find { |h| h["label"] == "Portion Note" }
      metadata_values = metadata_object["value"]
      expect(metadata_values).to be_kind_of Array
      expect(metadata_values).to include "test value1"
      expect(metadata_values).to include "RCPPA BL980.G7 B66 1982"
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
      change_set = ScannedResourceChangeSet.new(scanned_resource)
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
      FactoryBot.create_for_repository(:scanned_map, description: "Test Description")
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

  context "when given a scanned resource which was ingested with its mets file as an attached member" do
    let(:file) { fixture_file_upload("mets/pudl0001-4612596.mets", "application/xml; schema=mets") }
    before do
      stub_bibdata(bib_id: "123456")
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

  context "when given a scanned resource with audio files" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
    let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file], downloadable: "none") }
    let(:file) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "") }
    let(:logical_structure) { nil }
    before do
      stub_bibdata(bib_id: "123456")
    end
    context "when downloading is enabled" do
      let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file], downloadable: "public") }
      it "doesn't block download" do
        change_set_persister.save(change_set: change_set)
        output = manifest_builder.build

        expect(output["service"]).to be_nil
      end
    end

    it "builds a manifest for an ArchivalMediaBag ingested Recording", run_real_characterization: true, run_real_derivatives: true do
      bag_path = Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag")
      user = User.first
      stub_pulfa(pulfa_id: "C0652")
      stub_pulfa(pulfa_id: "C0652_c0377")
      IngestArchivalMediaBagJob.perform_now(collection_component: "C0652", bag_path: bag_path, user: user)

      recording = query_service.custom_queries.find_by_property(property: :local_identifier, value: "32101047382401").last
      manifest_builder = described_class.new(recording)
      output = manifest_builder.build
      expect(output).to include "items"
      canvases = output["items"]
      expect(canvases.length).to eq 2
      expect(canvases.first["rendering"].map { |h| h["label"] }).to contain_exactly "Download the mp3"
      expect(canvases.first["items"][0]["items"][0]["body"]["duration"]).to eq 0.255
    end

    context "when given a multi-volume recording", run_real_characterization: true, run_real_derivatives: true do
      subject(:manifest_builder) { described_class.new(scanned_resource) }

      let(:file1) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "") }
      let(:file2) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "") }
      let(:volume1) { FactoryBot.create_for_repository(:scanned_resource, files: [file1]) }
      let(:volume2) { FactoryBot.create_for_repository(:scanned_resource, files: [file2]) }
      let(:scanned_resource) do
        sr = FactoryBot.create_for_repository(:recording)
        cs = ScannedResourceChangeSet.new(sr)
        cs.validate(member_ids: [volume1.id, volume2.id])
        change_set_persister.save(change_set: cs)
      end
      let(:output) { manifest_builder.build }

      it "generates the Ranges for the audio FileSets" do
        expect(output).to be_kind_of Hash
        expect(output["@context"]).to include "http://iiif.io/api/presentation/3/context.json"
        expect(output["type"]).to eq "Manifest"
        expect(output["items"].length).to eq 2

        first_canvas = output["items"].first
        expect(first_canvas).to include "label" => { "@none" => ["32101047382401_1_pm.wav"] }

        last_canvas = output["items"].last
        expect(last_canvas).to include "label" => { "@none" => ["32101047382401_1_pm.wav"] }

        expect(output).to include "structures"
        ranges = output["structures"]
        expect(ranges.length).to eq 2

        expect(ranges.first["items"].length).to eq 1
        expect(ranges.first["items"].first).to include "label" => { "@none" => ["32101047382401_1_pm.wav"] }
        child_ranges = ranges.first["items"]
        expect(child_ranges.length).to eq 1
        expect(child_ranges.first).to include "items"
        range_canvases = child_ranges.first["items"]
        expect(range_canvases.length).to eq 1
        expect(range_canvases.first).to include "label" => [{ "@none" => ["32101047382401_1_pm.wav"] }]

        expect(ranges.last["items"].length).to eq 1
        expect(ranges.last["items"].first).to include "label" => { "@none" => ["32101047382401_1_pm.wav"] }
        child_ranges = ranges.last["items"]
        expect(child_ranges.length).to eq 1
        expect(child_ranges.first).to include "items"
        range_canvases = child_ranges.first["items"]
        expect(range_canvases.length).to eq 1
        expect(range_canvases.first).to include "label" => [{ "@none" => ["32101047382401_1_pm.wav"] }]
      end
    end

    context "when given a multi-volume recording with thumbnails", run_real_characterization: true, run_real_derivatives: true do
      subject(:manifest_builder) { described_class.new(scanned_resource) }

      let(:audio_file1) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "") }
      let(:image_file1) { fixture_file_upload("files/example.tif") }
      let(:audio_file2) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "") }
      let(:image_file2) { fixture_file_upload("files/example.tif") }
      let(:volume1) { FactoryBot.create_for_repository(:scanned_resource, files: [audio_file1, image_file1]) }
      let(:volume2) { FactoryBot.create_for_repository(:scanned_resource, files: [audio_file2, image_file2]) }
      let(:scanned_resource) do
        sr = FactoryBot.create_for_repository(:recording)
        cs = ScannedResourceChangeSet.new(sr)
        cs.validate(member_ids: [volume1.id, volume2.id])
        change_set_persister.save(change_set: cs)
      end
      let(:output) { manifest_builder.build }

      it "generates the posterCanvas for the Manifest" do
        expect(output).to be_kind_of Hash
        expect(output["@context"]).to include "http://iiif.io/api/presentation/3/context.json"
        expect(output["type"]).to eq "Manifest"
        expect(output["items"].length).to eq 2
        first_item = output["items"].first
        expect(first_item).to include "label" => { "@none" => ["32101047382401_1_pm.wav"] }

        expect(output).to include("posterCanvas")
        poster_canvas = output["posterCanvas"]
        pages = poster_canvas["items"]
        expect(pages.length).to eq(1)
        annotations = pages.first["items"]
        expect(annotations.length).to eq(1)
        body = annotations.last["body"]
        expect(body["type"]).to eq("Image")
      end
    end

    context "when given an ArchivalMediaCollection", run_real_characterization: true, run_real_derivatives: true do
      let(:collection) { query_service.custom_queries.find_by_property(property: :source_metadata_identifier, value: "C0652").last }
      let(:collection_members) { collection.decorate.members }
      let(:recording) { collection_members.first.decorate.members.first }
      let(:manifest_builder) { described_class.new(collection) }
      let(:output) { manifest_builder.build }

      before do
        bag_path = Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag")
        user = User.first
        stub_pulfa(pulfa_id: "C0652")
        stub_pulfa(pulfa_id: "C0652_c0377")
        IngestArchivalMediaBagJob.perform_now(collection_component: "C0652", bag_path: bag_path, user: user)
      end

      it "builds a presentation 3 manifest with recordings as separate canvases" do
        expect(output).to be_kind_of Hash
        expect(output["@context"]).to include "http://iiif.io/api/presentation/3/context.json"
        expect(output["type"]).to eq "Manifest"
        expect(output["items"].length).to eq 2
        expect(output["items"].first).to include "label" => { "@none" => ["32101047382401_1"] }
        expect(output["items"].last).to include "label" => { "@none" => ["32101047382401_2"] }

        expect(output["structures"].length).to eq 2
        expect(output["structures"].first).to include "label" => { "@none" => ["32101047382401_1"] }
        expect(output["structures"].last).to include "label" => { "@none" => ["32101047382401_2"] }
      end
    end

    it "builds a presentation 3 manifest", run_real_characterization: true do
      output = change_set_persister.save(change_set: change_set)
      output.logical_structure = [
        { label: "Logical", nodes: [{ proxy: output.member_ids.last }, { label: "Bla", nodes: [{ proxy: output.member_ids.first }] }] }
      ]

      change_set_persister.persister.save(resource: output)
      output = manifest_builder.build
      # pres 3 context is always an array
      expect(output["@context"]).to include "http://iiif.io/api/presentation/3/context.json"
      # Logical structure should be able to have nested and un-nested members.
      expect(output["structures"][0]["items"][0]["id"]).to include "#t="
      expect(output["structures"][1]["items"][0]["items"][0]["id"]).to include "#t="
      expect(output["behavior"]).to eq ["auto-advance"]
      # downloading is blocked
      expect(output["service"][0]).to eq ({ "@context" => "http://universalviewer.io/context.json", "profile" => "http://universalviewer.io/ui-extensions-profile", "disableUI" => ["mediaDownload"] })
    end
    context "with no logical structure", run_real_characterization: true do
      let(:logical_structure) { nil }
      it "builds a presentation 3 manifest with a default table of contents" do
        change_set_persister.save(change_set: change_set)
        output = manifest_builder.build
        # A default table of contents should display
        expect(output["structures"][0]["items"][0]["id"]).to include "#t="
        expect(output["structures"][0]["label"]["@none"]).to eq ["32101047382401_1_pm.wav"]
      end
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
      stub_bibdata(bib_id: "123456")
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
end
