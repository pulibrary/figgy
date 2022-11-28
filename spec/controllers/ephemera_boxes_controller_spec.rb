# frozen_string_literal: true
require "rails_helper"
include FixtureFileUpload

RSpec.describe EphemeraBoxesController, type: :controller do
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
      it "has a form for creating ephemera boxes" do
        FactoryBot.create_for_repository(:ephemera_box)

        get :new
        expect(response.body).to have_field "Box number"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "folders" do
    context "when not logged in" do
      let(:user) { nil }
      it "redirects CanCan::AccessDenied error to login" do
        box = FactoryBot.create_for_repository(:private_ephemera_box)
        get :folders, params: { id: box.id }
        expect(response).to redirect_to("/users/auth/cas")
      end
    end
    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "renders a JSON list of a project's folders" do
        folder = FactoryBot.create_for_repository(:ephemera_folder)
        box = FactoryBot.create_for_repository(:ephemera_box, member_ids: folder.id)

        get :folders, params: { id: box.id.to_s, formats: :json }

        json = JSON.parse(response.body)
        expect(json["data"].length).to eq 1
        expect(json["data"][0]["folder_number"]).to eq folder.folder_number.first
        expect(json["data"][0]["workflow_state"]).to eq "<span class=\"badge badge-info\">Needs QA</span>"
        expect(json["data"][0]["title"]).to eq folder.title
        expect(json["data"][0]["barcode"]).to eq folder.barcode.first
        expect(json["data"][0]["genre"]).to eq folder.genre.first
        expect(json["data"][0]["actions"]).to have_link "View", href: "/catalog/parent/#{box.id}/#{folder.id}"
        expect(json["data"][0]["actions"]).to have_link "Edit", href: "/concern/ephemera_folders/#{folder.id}/edit"
        expect(json["data"][0]["actions"]).not_to have_link "Delete"
      end
    end
  end

  describe "create" do
    let(:user) { FactoryBot.create(:admin) }
    let(:valid_params) do
      {
        barcode: ["00000000000000"],
        box_number: ["1"],
        rights_statement: RightsStatements.no_known_copyright.to_s,
        visibility: "restricted"
      }
    end
    let(:invalid_params) do
      {
        barcode: nil,
        box_number: nil,
        rights_statement: "Test Statement",
        visibility: "restricted"
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
    it "can create an ephemera box" do
      post :create, params: { ephemera_box: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      resource = find_resource(id)
      expect(resource.box_number).to contain_exactly "1"
      expect(resource.state).to contain_exactly "new"
    end
    it "will index the project if possible" do
      project = FactoryBot.create_for_repository(:ephemera_project)
      post :create, params: { ephemera_box: valid_params.merge(append_id: project.id.to_s) }

      id = query_service.find_all_of_model(model: EphemeraBox).to_a.first.id
      solr_record = Blacklight.default_index.connection.get("select", params: { q: "id:#{id}", rows: 1 })["response"]["docs"].first
      expect(solr_record["ephemera_project_ssim"]).to eq project.title
    end
    context "when something bad goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: { ephemera_box: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: { ephemera_box: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    it "renders the form if it doesn't create a ephemera box" do
      post :create, params: { ephemera_box: invalid_params }
      expect(response).to render_template "base/new"
    end
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_box }
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a book" do
      ephemera_box = FactoryBot.create_for_repository(:ephemera_box)
      ephemera_project = FactoryBot.create_for_repository(:ephemera_project, member_ids: ephemera_box.id)
      delete :destroy, params: { id: ephemera_box.id.to_s }

      expect(response).to redirect_to solr_document_path(id: ephemera_project.id)
      expect { query_service.find_by(id: ephemera_box.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_box }
      it_behaves_like "an access controlled edit request"
    end
    context "when a ephemera box doesn't exist" do
      render_views
      it "raises an error" do
        get :edit, params: { id: "test" }
        expect(response).to have_http_status(404)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        ephemera_box = FactoryBot.create_for_repository(:ephemera_box)
        get :edit, params: { id: ephemera_box.id.to_s }

        expect(response.body).to have_field "Box number", with: ephemera_box.box_number.first
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "attach_drive" do
    let(:user) { FactoryBot.create(:admin) }

    context "when it exists" do
      render_views
      it "renders a form" do
        ephemera_box = FactoryBot.create_for_repository(:ephemera_box)
        get :attach_drive, params: { id: ephemera_box.id.to_s }

        expect(response.body).to have_field "Drive barcode"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "update" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_box }
      let(:extra_params) { { ephemera_box: { title: ["Two"] } } }
      it_behaves_like "an access controlled update request"
    end
    context "when a ephemera box doesn't exist" do
      render_views
      it "raises an error" do
        patch :update, params: { id: "test" }
        expect(response).to have_http_status(404)
      end
    end
    it_behaves_like "a workflow controller", :ephemera_box
    context "when it does exist" do
      it "saves it and redirects" do
        ephemera_box = FactoryBot.create_for_repository(:ephemera_box)
        patch :update, params: { id: ephemera_box.id.to_s, ephemera_box: { box_number: ["Two"] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/#{ephemera_box.id}"
        id = response.location.gsub("http://test.host/catalog/", "")
        reloaded = find_resource(id)

        expect(reloaded.box_number).to eq ["Two"]
      end
      it "renders the form if it fails validations" do
        ephemera_box = FactoryBot.create_for_repository(:ephemera_box)
        patch :update, params: { id: ephemera_box.id.to_s, ephemera_box: { box_number: nil } }

        expect(response).to render_template "base/edit"
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
