# frozen_string_literal: true

require "rails_helper"
include FixtureFileUpload

RSpec.describe EphemeraProjectsController, type: :controller do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  before do
    sign_in user if user
  end

  describe "new" do
    it_behaves_like "an access controlled new request"

    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has a form for creating ephemera projects" do
        FactoryBot.create_for_repository(:ephemera_project)

        get :new
        expect(response.body).to have_field "Title"
        expect(response.body).to have_button "Save"
        expect(response.body).not_to have_field "Top Language"
      end
    end
  end

  describe "create" do
    let(:user) { FactoryBot.create(:admin) }
    let(:valid_params) do
      {
        title: ["Project 1"],
        slug: ["test-project-1234"]
      }
    end
    let(:invalid_params) do
      {
        title: nil
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
    it "can create an ephemera project" do
      post :create, params: {ephemera_project: valid_params}

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      expect(find_resource(id).title).to contain_exactly "Project 1"
    end
    context "when something bad goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: {ephemera_project: valid_params}
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: {ephemera_project: valid_params}
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    it "renders the form if it doesn't create a ephemera project" do
      post :create, params: {ephemera_project: invalid_params}
      expect(response).to render_template "base/new"
    end
  end

  describe "index" do
    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has lists all ephemera projects" do
        project = FactoryBot.create_for_repository(:ephemera_project)

        get :index
        expect(response.body).to have_content "Test Project"
        expect(response.body).not_to have_content project.title.to_s
      end
    end
  end

  describe "folders" do
    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "renders a JSON list of a project's folders" do
        genre = FactoryBot.create_for_repository(:ephemera_term, label: "Testing")
        folder = FactoryBot.create_for_repository(:ephemera_folder, genre: genre.id)
        project = FactoryBot.create_for_repository(:ephemera_project, member_ids: folder.id)
        query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
        allow(query_service).to receive(:find_by).and_call_original

        get :folders, params: {id: project.id.to_s, formats: :json}

        json = JSON.parse(response.body)
        expect(json["data"].length).to eq 1
        expect(json["data"][0]["folder_number"]).to eq folder.folder_number.first
        expect(json["data"][0]["workflow_state"]).to eq "<span class=\"label label-info\">Needs QA</span>"
        expect(json["data"][0]["title"]).to eq folder.title
        expect(json["data"][0]["barcode"]).to eq folder.barcode.first
        expect(json["data"][0]["genre"]).to eq "Testing"
        expect(json["data"][0]["actions"]).not_to be_blank
        expect(query_service).to have_received(:find_by).with(id: project.id).exactly(1).times
        expect(query_service).not_to have_received(:find_by).with(id: genre.id)
      end
    end
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_project }
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a book" do
      ephemera_project = FactoryBot.create_for_repository(:ephemera_project)
      delete :destroy, params: {id: ephemera_project.id.to_s}

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: ephemera_project.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_project }
      it_behaves_like "an access controlled edit request"
    end
    context "when a ephemera project doesn't exist" do
      it "raises an error" do
        get :edit, params: {id: "test"}
        expect(response).to redirect_to_not_found
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        ephemera_project = FactoryBot.create_for_repository(:ephemera_project)
        get :edit, params: {id: ephemera_project.id.to_s}

        expect(response.body).to have_field "Title", with: ephemera_project.title.first
        expect(response.body).to have_button "Save"
      end
    end
    context "when it has a language field" do
      render_views
      it "renders top language field" do
        ephemera_vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary)
        ephemera_field = FactoryBot.create_for_repository(:ephemera_field, member_of_vocabulary_id: [ephemera_vocabulary.id])
        ephemera_project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [ephemera_field.id])
        FactoryBot.create_for_repository(:ephemera_term, label: "English", member_of_vocabulary_id: [ephemera_vocabulary.id])
        get :edit, params: {id: ephemera_project.id.to_s}

        expect(response.body).to have_field "Top Language"
      end
    end
  end

  describe "update" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_project }
      let(:extra_params) { {ephemera_project: {title: ["Two"]}} }
      it_behaves_like "an access controlled update request"
    end
    context "when a ephemera project doesn't exist" do
      it "raises an error" do
        patch :update, params: {id: "test"}
        expect(response).to redirect_to_not_found
      end
    end
    context "when it does exist" do
      let(:eng) { FactoryBot.create_for_repository(:ephemera_term, label: "English") }
      it "saves it and redirects" do
        ephemera_project = FactoryBot.create_for_repository(:ephemera_project)
        patch :update, params: {id: ephemera_project.id.to_s, ephemera_project: {title: ["Two"], slug: ["updated-slug"], top_language: [eng.id.to_s]}}

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/#{ephemera_project.id}"
        id = response.location.gsub("http://test.host/catalog/", "")
        reloaded = find_resource(id)

        expect(reloaded.title).to eq ["Two"]
        expect(reloaded.slug).to eq ["updated-slug"]
        expect(reloaded.top_language).to eq [eng.id]
      end
      it "renders the form if it fails validations" do
        ephemera_project = FactoryBot.create_for_repository(:ephemera_project)
        patch :update, params: {id: ephemera_project.id.to_s, ephemera_project: {title: nil}}

        expect(response).to render_template "base/edit"
      end
    end
  end

  describe "GET /concern/ephemera_project/:id/manifest", manifest: true do
    let(:ephemera_project) { FactoryBot.create_for_repository(:ephemera_project) }

    it "returns a IIIF manifest for an ephemera project", manifest: true do
      get :manifest, params: {id: ephemera_project.id.to_s, format: :json}
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:metadata]).not_to be_empty
      expect(manifest_response[:metadata][0]).to include label: "Exhibit", value: [ephemera_project.decorate.slug]
    end

    context "when the project has folders" do
      let(:ephemera_box1) { FactoryBot.create_for_repository(:ephemera_box, member_ids: folder1.id) }
      let(:ephemera_box2) { FactoryBot.create_for_repository(:ephemera_box) }
      let(:folder1) { FactoryBot.create_for_repository(:ephemera_folder) }
      let(:ephemera_project) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [ephemera_box1.id, ephemera_box2.id]) }

      before do
        ephemera_box1
        ephemera_box2
      end

      it "returns manifests for the ephemera boxes", manifest: true do
        get :manifest, params: {id: ephemera_project.id.to_s, format: :json}
        manifest_response = MultiJson.load(response.body, symbolize_keys: true)

        expect(response.headers["Content-Type"]).to include "application/json"
        expect(manifest_response[:metadata]).not_to be_empty
        expect(manifest_response[:metadata][0]).to include label: "Exhibit", value: [ephemera_project.decorate.slug]
        expect(manifest_response[:manifests].length).to eq 1
        expect(manifest_response[:manifests][0][:@id]).to eq "http://www.example.com/concern/ephemera_folders/#{folder1.id}/manifest"
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
