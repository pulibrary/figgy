# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe ScannedResourcesController do
  with_queue_adapter :inline
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:resource_klass) { ScannedResource }
  let(:manifestable_factory) { :complete_scanned_resource }

  before do
    sign_in user if user
  end

  it_behaves_like "a BaseResourceController"

  describe "new" do
    context "when not logged in but an auth token is given" do
      it "renders the full manifest" do
        resource = FactoryBot.create_for_repository(:complete_campus_only_scanned_resource)
        authorization_token = AuthToken.create!(group: ["admin"], label: "Admin Token")
        get :manifest, params: { id: resource.id, format: :json, auth_token: authorization_token.token }

        expect(response).to be_success
        expect(response.body).not_to eq "{}"
      end
    end
    context "when not logged in" do
      it "returns a 403" do
        resource = FactoryBot.create_for_repository(:complete_campus_only_scanned_resource)
        get :manifest, params: { id: resource.id, format: :json }
        expect(response).to be_forbidden
      end
    end
  end

  describe "create" do
    let(:user) { FactoryBot.create(:admin) }
    let(:valid_params) do
      {
        title: ["Title 1", "Title 2"],
        rights_statement: "http://rightsstatements.org/vocab/CNE/1.0/",
        visibility: "restricted"
      }
    end
    let(:invalid_params) do
      {
        title: [""],
        rights_statement: "Test Statement",
        visibility: "restricted"
      }
    end
    context "when asked to save and import" do
      before do
        allow(BrowseEverything).to receive(:config).and_return(
          file_system: {
            home: Rails.root.join("spec", "fixtures", "staged_files").to_s
          }
        )
        stub_bibdata(bib_id: "123456")
        stub_bibdata(bib_id: "4609321")
        stub_bibdata(bib_id: "1791261")
      end
      it "can create and import at once" do
        post :create, params: {
          scanned_resource: {
            source_metadata_identifier: "123456",
            rights_statement: "http://rightsstatements.org/vocab/CNE/1.0/",
            visibility: "restricted"
          },
          commit: "Save and Ingest"
        }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
        resource = find_resource(id)

        expect(resource.member_ids.length).to eq 2
      end

      it "can create and import a MVW" do
        post :create, params: {
          scanned_resource: {
            source_metadata_identifier: "4609321",
            rights_statement: "http://rightsstatements.org/vocab/CNE/1.0/",
            visibility: "restricted"
          },
          commit: "Save and Ingest"
        }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
        resource = find_resource(id)

        expect(resource.member_ids.length).to eq 2
        members = query_service.find_members(resource: resource)
        expect(members.flat_map(&:title)).to contain_exactly "Vol 1", "Vol 2"
      end

      context "when ingesting a directory with WAV files" do
        let(:tika_output) { tika_wav_output }
        it "can create and import audio reserves" do
          post :create, params: {
            scanned_resource: {
              source_metadata_identifier: "1791261",
              rights_statement: "http://rightsstatements.org/vocab/CNE/1.0/",
              visibility: "restricted"
            },
            commit: "Save and Ingest"
          }

          expect(response).to be_redirect
          expect(response.location).to start_with "http://test.host/catalog/"
          id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
          resource = find_resource(id)

          expect(resource.member_ids.length).to eq 1
          file_set = find_resource(resource.member_ids.first)
          expect(file_set.file_metadata.length).to eq 2
          expect(file_set.original_file).not_to be nil
          expect(file_set.original_file.label).to eq ["1791261_0701.wav"]
          expect(file_set.original_file.mime_type).to eq ["audio/x-wav"]
        end
      end
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource) }

    render_views

    it "does not render a collections form field" do
      get :edit, params: { id: scanned_resource.id.to_s }

      expect(response.body).to have_select "Collections", name: "scanned_resource[member_of_collection_ids][]"
    end

    context "when it has a member resource" do
      let(:member_resource) { FactoryBot.create_for_repository(:scanned_resource) }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [member_resource.id]) }

      before do
        scanned_resource
      end

      it "does not render a collections form field" do
        get :edit, params: { id: member_resource.id.to_s }

        expect(response.body).not_to have_select "Collections", name: "scanned_resource[member_of_collection_ids][]"
      end
    end
  end

  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html" do
      context "when it does exist" do
        it_behaves_like "a workflow controller", :scanned_resource
      end
    end
  end

  describe "structure" do
    let(:user) { FactoryBot.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "redirects to login or root" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)

        get :structure, params: { id: scanned_resource.id.to_s }
        expect(response).to be_redirect
      end
    end
    context "when a scanned resource doesn't exist" do
      it "raises an error" do
        expect { get :structure, params: { id: "banana" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a structure editor form" do
        file_set = FactoryBot.create_for_repository(:file_set)
        scanned_resource = FactoryBot.create_for_repository(
          :scanned_resource,
          member_ids: file_set.id,
          thumbnail_id: file_set.id,
          logical_structure: [
            { label: "testing", nodes: [{ label: "Chapter 1", nodes: [{ proxy: file_set.id }] }] }
          ]
        )

        query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
        allow(query_service).to receive(:find_by).with(id: scanned_resource.id).and_call_original
        allow(query_service).to receive(:find_inverse_references_by)
        get :structure, params: { id: scanned_resource.id.to_s }

        expect(response.body).to have_selector "li[data-proxy='#{file_set.id}']"
        expect(response.body).to have_field("label", with: "Chapter 1")
        expect(response.body).to have_link scanned_resource.title.first, href: solr_document_path(id: scanned_resource.id)
        expect(query_service).not_to have_received(:find_inverse_references_by)
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end

  context "when an admin" do
    let(:user) { FactoryBot.create(:admin) }

    # This block tests functionality defined in `app/controllers/concerns/browse_everythingable.rb`
    #   Acts as a 'master spec' in this regard
    describe "POST /concern/scanned_resources/:id/browse_everything_files" do
      let(:file) { File.open(Rails.root.join("spec", "fixtures", "files", "example.tif")) }
      let(:params) do
        {
          "selected_files" => {
            "0" => {
              "url" => "file://#{file.path}",
              "file_name" => File.basename(file.path),
              "file_size" => file.size
            }
          }
        }
      end
      context "when given an empty array of selected files" do
        it "doesn't upload anything" do
          resource = FactoryBot.create_for_repository(:scanned_resource)

          post :browse_everything_files, params: { id: resource.id, selected_files: {} }
          reloaded = adapter.query_service.find_by(id: resource.id)

          expect(response).to be_redirect
          expect(reloaded.member_ids.length).to eq 0
        end
      end

      context "when a server-side error is encountered while downloading a file" do
        let(:expiry_time) { (Time.current + 3600).xmlschema }
        let(:params) do
          {
            "selected_files" => {
              "0" => {
                "url" => "https://retrieve.cloud.example.com/some/dir/file.pdf",
                "auth_header" => { "Authorization" => "Bearer ya29.kQCEAHj1bwFXr2AuGQJmSGRWQXpacmmYZs4kzCiXns3d6H1ZpIDWmdM8" },
                "expires" => expiry_time,
                "file_name" => "file.pdf",
                "file_size" => "1874822"
              }
            }
          }
        end
        let(:http_request) { instance_double(Typhoeus::Request) }
        let(:cloud_response) { Typhoeus::Response.new }

        before do
          allow(cloud_response).to receive(:code).and_return(403)
          allow(http_request).to receive(:on_headers).and_yield(cloud_response)
          allow(Typhoeus::Request).to receive(:new).and_return(http_request)
        end

        it "does not persist any files" do
          resource = FactoryBot.create_for_repository(:scanned_resource)

          post :browse_everything_files, params: { id: resource.id, selected_files: params["selected_files"] }
          reloaded = adapter.query_service.find_by(id: resource.id)

          expect(response).to be_redirect
          expect(reloaded.member_ids).to be_empty
        end
      end
      it "uploads files" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        # Ensure that indexing is always safe and done at the end.
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(Valkyrie::MetadataAdapter.find(:index_solr).persister)
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save).and_call_original
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_call_original

        post :browse_everything_files, params: { id: resource.id, selected_files: params["selected_files"] }
        reloaded = adapter.query_service.find_by(id: resource.id)

        expect(reloaded.member_ids.length).to eq 1
        expect(reloaded.pending_uploads).to be_empty
        expect(Valkyrie::MetadataAdapter.find(:index_solr).persister).not_to have_received(:save)
        expect(Valkyrie::MetadataAdapter.find(:index_solr).persister).to have_received(:save_all).at_least(1).times

        file_sets = Valkyrie.config.metadata_adapter.query_service.find_members(resource: reloaded)
        expect(file_sets.first.file_metadata.length).to eq 2
      end
      it "tracks pending uploads" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        allow(BrowseEverythingIngestJob).to receive(:perform_later).and_return(true)

        post :browse_everything_files, params: { id: resource.id, selected_files: params["selected_files"] }
        reloaded = adapter.query_service.find_by(id: resource.id)

        pending_upload = reloaded.pending_uploads[0]
        expect(pending_upload.file_name).to eq [File.basename(file.path)]
        expect(pending_upload.url).to eq ["file://#{file.path}"]
        expect(pending_upload.file_size).to eq [file.size]
        expect(pending_upload.created_at).not_to be_blank
      end
    end
  end

  describe "GET /concern/scanned_resources/save_and_ingest/:id" do
    let(:user) { FactoryBot.create(:admin) }
    before do
      allow(BrowseEverything).to receive(:config).and_return(
        file_system: {
          home: Rails.root.join("spec", "fixtures", "staged_files").to_s
        }
      )
    end
    it "returns JSON for whether a directory exists" do
      get :save_and_ingest, params: { format: :json, id: "123456" }

      output = JSON.parse(response.body, symbolize_keys: true)

      expect(output["exists"]).to eq true
      expect(output["location"]).to eq "DPUL/Santa/ready/123456"
      expect(output["file_count"]).to eq 2
    end
    it "returns JSON for when it's a MVW" do
      get :save_and_ingest, params: { format: :json, id: "4609321" }

      output = JSON.parse(response.body, symbolize_keys: true)

      expect(output["exists"]).to eq true
      expect(output["location"]).to eq "DPUL/Santa/ready/4609321"
      expect(output["file_count"]).to eq 0
      expect(output["volume_count"]).to eq 2
    end
    context "when a folder doesn't exist" do
      it "returns JSON appropriately" do
        get :save_and_ingest, params: { format: :json, id: "1234" }

        output = JSON.parse(response.body, symbolize_keys: true)

        expect(output["exists"]).to eq false
        expect(output["location"]).to be_nil
        expect(output["file_count"]).to be_nil
      end
    end
  end

  describe "GET /concern/scanned_resources/:id/manifest", run_real_derivatives: true do
    with_queue_adapter :inline
    let(:user) { FactoryBot.create(:admin) }
    let(:file) do
      fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "audio/x-wav")
    end
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
    let(:file_set_id) { scanned_resource.decorate.file_sets.first.id }
    let(:file_id) { scanned_resource.decorate.file_sets.first.derivative_files.first.id }
    let(:rendering_download) do
      "http://www.example.com/downloads/#{file_set_id}/file/#{file_id}"
    end

    before do
      sign_in user
    end

    context "when a ScannedResource has a FileSet containing audio files" do
      it "generates a manifest with all FileSets as ranges" do
        get :manifest, params: { format: :json, id: scanned_resource.id }

        expect(response.status).to eq 200
        expect(response.body).not_to be_empty
        manifest_values = JSON.parse(response.body)
        expect(manifest_values["rendering"]).not_to be_empty
        expect(manifest_values["rendering"].first).to include("id" => rendering_download)
        expect(manifest_values["rendering"].first).to include("label" => { "en" => ["Download as MP3"] })
        expect(manifest_values["rendering"].first).to include("format" => "audio/mp3")
      end

      context "with a structure" do
        let(:file2) do
          fixture_file_upload("files/audio_file.wav")
        end
        let(:scanned_resource) do
          FactoryBot.create_for_repository(:scanned_resource, files: [file, file2])
        end
        let(:file_set_2_id) { scanned_resource.decorate.file_sets.last.id }
        let(:logical_structure) do
          [
            {
              label: "Album 1",
              nodes: [
                {
                  label: "Track 1",
                  nodes: [{ proxy: file_set_id }]
                },
                {
                  label: "Track 2",
                  nodes: [{ proxy: file_set_2_id }]
                }
              ]
            }
          ]
        end
        let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
        let(:range_id) { file_set_id }
        before do
          cs = ScannedResourceChangeSet.new(scanned_resource, logical_structure: logical_structure)
          change_set_persister.save(change_set: cs)
        end
        describe "GET /concern/scanned_resources/:id/manifest" do
          it "generates a manifest with a ranges for FileSets" do
            get :manifest, params: { format: :json, id: scanned_resource.id }

            expect(response.status).to eq 200
            expect(response.body).not_to be_empty
            manifest_values = JSON.parse(response.body)
            manifest_renderings = manifest_values["rendering"]

            expect(manifest_renderings).not_to be_empty
            expect(manifest_renderings.first).to include("id" => rendering_download)
            expect(manifest_renderings.first).to include("label" => { "en" => ["Download as MP3"] })
            expect(manifest_renderings.first).to include("format" => "audio/mp3")

            manifest_structures = manifest_values["structures"]
            expect(manifest_structures).not_to be_empty
            top_range = manifest_structures.first

            expect(top_range).to include("items")
            child_ranges = top_range["items"]

            expect(child_ranges).not_to be_empty
            expect(child_ranges.length).to eq(2)
            expect(child_ranges.first["id"]).to eq("http://www.example.com/concern/scanned_resources/#{scanned_resource.id}/manifest/range/r#{file_set_id}")
            expect(child_ranges.last["id"]).to eq("http://www.example.com/concern/scanned_resources/#{scanned_resource.id}/manifest/range/r#{file_set_2_id}")
          end
        end
        context "with a logical structure which is incomplete" do
          let(:logical_structure) do
            [
              {
                label: "Album 1",
                nodes: [
                  {
                    label: "Track 1",
                    nodes: []
                  }
                ]
              }
            ]
          end
          it "generates random URIs for the child Ranges containing the FileSets" do
            get :manifest, params: { format: :json, id: scanned_resource.id }

            expect(response.status).to eq 200
            expect(response.body).not_to be_empty
            manifest_values = JSON.parse(response.body)

            manifest_structures = manifest_values["structures"]
            expect(manifest_structures).not_to be_empty
            top_range = manifest_structures.first

            expect(top_range).to include("items")
            child_ranges = top_range["items"]

            expect(child_ranges).not_to be_empty
            expect(child_ranges.length).to eq(1)

            expect(child_ranges.first["id"]).not_to eq("http://www.example.com/concern/scanned_resources/#{scanned_resource.id}/manifest/range/r#{file_set_id}")
            expect(child_ranges.first["id"]).to include("http://www.example.com/concern/scanned_resources/#{scanned_resource.id}/manifest/range/r")
          end
        end
        describe "GET /concern/scanned_resources/:id/manifest?range_id=" do
          xit "generates a manifest with only a range for the requested FileSet" do
            get :manifest, params: { format: :json, id: scanned_resource.id, param: { range_id: range_id } }

            expect(response.status).to eq 200
            expect(response.body).not_to be_empty
            manifest_values = JSON.parse(response.body)
            manifest_renderings = manifest_values["rendering"]

            expect(manifest_renderings).not_to be_empty
            expect(manifest_renderings.first).to include("id" => rendering_download)
            expect(manifest_renderings.first).to include("label" => { "en" => ["Download as MP3"] })
            expect(manifest_renderings.first).to include("format" => "audio/mp3")

            manifest_structures = manifest_values["structures"]
            expect(manifest_structures).not_to be_empty
            top_range = manifest_structures.first

            expect(top_range).to include("items")
            child_ranges = top_range["items"]

            expect(child_ranges).not_to be_empty
            expect(child_ranges.length).to eq(1)
            expect(child_ranges.first["id"]).to eq("http://www.example.com/concern/scanned_resources/#{scanned_resource.id}/manifest/range/r#{file_set_id}")
          end
        end
      end
    end
  end
end
