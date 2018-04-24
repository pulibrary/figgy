# frozen_string_literal: true
require 'rails_helper'
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

  it_behaves_like 'a BaseResourceController'

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
        title: ['Title 1', 'Title 2'],
        rights_statement: 'Test Statement',
        visibility: 'restricted'
      }
    end
    let(:invalid_params) do
      {
        title: [""],
        rights_statement: 'Test Statement',
        visibility: 'restricted'
      }
    end
    context "when asked to save and import" do
      before do
        allow(BrowseEverything).to receive(:config).and_return(
          file_system: {
            home: Rails.root.join("spec", "fixtures", "staged_files").to_s
          }
        )
        stub_bibdata(bib_id: '123456')
        stub_bibdata(bib_id: '4609321')
      end
      it "can create and import at once" do
        post :create, params: {
          scanned_resource: {
            source_metadata_identifier: "123456",
            rights_statement: 'Test Statement',
            visibility: 'restricted'
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
            rights_statement: 'Test Statement',
            visibility: 'restricted'
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
          logical_structure: [
            { label: 'testing', nodes: [{ label: 'Chapter 1', nodes: [{ proxy: file_set.id }] }] }
          ]
        )

        get :structure, params: { id: scanned_resource.id.to_s }

        expect(response.body).to have_selector "li[data-proxy='#{file_set.id}']"
        expect(response.body).to have_field('label', with: 'Chapter 1')
        expect(response.body).to have_link scanned_resource.title.first, href: solr_document_path(id: scanned_resource.id)
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
end
