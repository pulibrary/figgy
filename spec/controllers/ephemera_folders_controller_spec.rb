# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EphemeraFoldersController do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:valid_params) do
    {
      barcode: ['12345678901234'],
      folder_number: ['one'],
      title: ['test folder'],
      language: ['test language'],
      genre: ['test genre'],
      width: ['10'],
      height: ['20'],
      page_count: ['30'],
      rights_statement: 'Test Statement',
      visibility: 'restricted'
    }
  end
  let(:invalid_params) do
    {
      barcode: nil,
      folder_number: nil,
      title: nil,
      language: nil,
      genre: nil,
      width: nil,
      height: nil,
      page_count: nil,
      rights_statement: 'Test Statement',
      visibility: 'restricted'
    }
  end
  before do
    sign_in user if user
  end

  describe "new" do
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        expect { get :new }.to raise_error CanCan::AccessDenied
      end
    end

    context "when they have permission" do
      let(:user) { FactoryGirl.create(:admin) }
      render_views
      it "has a form for creating ephemera folders" do
        FactoryGirl.create_for_repository(:ephemera_folder)

        get :new
        expect(response.body).to have_field "Folder number"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "new" do
    context "when not logged in but an auth token is given" do
      it "renders the full manifest" do
        resource = FactoryGirl.create_for_repository(:campus_only_ephemera_folder)
        authorization_token = AuthToken.create(group: ["admin"])
        get :manifest, params: { id: resource.id, format: :json, auth_token: authorization_token.token }

        expect(response).to be_success
        expect(response.body).not_to eq "{}"
      end
    end
  end

  describe "create" do
    let(:user) { FactoryGirl.create(:admin) }

    context "when not an admin" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        expect { post :create, params: { ephemera_folder: valid_params } }.to raise_error CanCan::AccessDenied
      end
    end
    it "can create an ephemera folder" do
      post :create, params: { ephemera_folder: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/").gsub(/^id-/, "")
      expect(find_resource(id).folder_number).to contain_exactly "one"
    end
    context "when something bad goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: { ephemera_folder: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: { ephemera_folder: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    it "renders the form if it doesn't create a ephemera folder" do
      post :create, params: { ephemera_folder: invalid_params }
      expect(response).to render_template "valhalla/base/new"
    end
  end

  describe "destroy" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        ephemera_folder = FactoryGirl.create_for_repository(:ephemera_folder)
        expect { delete :destroy, params: { id: ephemera_folder.id.to_s } }.to raise_error CanCan::AccessDenied
      end
    end
    it "can delete a book" do
      ephemera_folder = FactoryGirl.create_for_repository(:ephemera_folder)
      delete :destroy, params: { id: ephemera_folder.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: ephemera_folder.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        ephemera_folder = FactoryGirl.create_for_repository(:ephemera_folder)

        expect { get :edit, params: { id: ephemera_folder.id.to_s } }.to raise_error CanCan::AccessDenied
      end
    end
    context "when a ephemera folder doesn't exist" do
      it "raises an error" do
        expect { get :edit, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        ephemera_folder = FactoryGirl.create_for_repository(:ephemera_folder)
        get :edit, params: { id: ephemera_folder.id.to_s }

        expect(response.body).to have_field "Folder number", with: ephemera_folder.folder_number.first
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "update" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        ephemera_folder = FactoryGirl.create_for_repository(:ephemera_folder)

        expect { patch :update, params: { id: ephemera_folder.id.to_s, ephemera_folder: { folder_number: ["Two"] } } }.to raise_error CanCan::AccessDenied
      end
    end
    context "when a ephemera folder doesn't exist" do
      it "raises an error" do
        expect { patch :update, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        ephemera_folder = FactoryGirl.create_for_repository(:ephemera_folder)
        patch :update, params: { id: ephemera_folder.id.to_s, ephemera_folder: { folder_number: ["Two"] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/id-#{ephemera_folder.id}"
        id = response.location.gsub("http://test.host/catalog/id-", "")
        reloaded = find_resource(id)

        expect(reloaded.folder_number).to eq ["Two"]
      end
      it "renders the form if it fails validations" do
        ephemera_folder = FactoryGirl.create_for_repository(:ephemera_folder)
        patch :update, params: { id: ephemera_folder.id.to_s, ephemera_folder: invalid_params }

        expect(response).to render_template "valhalla/base/edit"
      end
    end
  end

  context "when an admin" do
    let(:user) { FactoryGirl.create(:admin) }
    describe "GET /ephemera_folders/:id/file_manager" do
      it "sets the record and children variables" do
        child = FactoryGirl.create_for_repository(:file_set)
        parent = FactoryGirl.create_for_repository(:ephemera_folder, member_ids: child.id)

        get :file_manager, params: { id: parent.id }

        expect(assigns(:change_set).id).to eq parent.id
        expect(assigns(:children).map(&:id)).to eq [child.id]
      end
    end

    describe "POST /concern/ephemera_folders/:id/browse_everything_files" do
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
        resource = FactoryGirl.create_for_repository(:ephemera_folder)
        # Ensure that indexing is always safe and done at the end.
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(Valkyrie::MetadataAdapter.find(:index_solr).persister)
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save).and_call_original

        post :browse_everything_files, params: { id: resource.id, selected_files: params["selected_files"] }
        reloaded = adapter.query_service.find_by(id: resource.id)

        expect(reloaded.member_ids.length).to eq 1
        expect(reloaded.pending_uploads).to be_empty
        expect(Valkyrie::MetadataAdapter.find(:index_solr).persister).not_to have_received(:save)

        file_sets = Valkyrie.config.metadata_adapter.query_service.find_members(resource: reloaded)
        expect(file_sets.first.file_metadata.length).to eq 2
      end
      it "tracks pending uploads" do
        resource = FactoryGirl.create_for_repository(:ephemera_folder)
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

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
