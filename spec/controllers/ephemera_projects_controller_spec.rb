# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EphemeraProjectsController do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
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
      it "has a form for creating ephemera projects" do
        FactoryGirl.create_for_repository(:ephemera_project)

        get :new
        expect(response.body).to have_field "Name"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "create" do
    let(:user) { FactoryGirl.create(:admin) }
    let(:valid_params) do
      {
        name: ['Project 1']
      }
    end
    let(:invalid_params) do
      {
        name: nil
      }
    end
    context "when not an admin" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        expect { post :create, params: { ephemera_project: valid_params } }.to raise_error CanCan::AccessDenied
      end
    end
    it "can create an ephemera project" do
      post :create, params: { ephemera_project: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/").gsub(/^id-/, "")
      expect(find_resource(id).name).to contain_exactly "Project 1"
    end
    context "when something bad goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: { ephemera_project: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: { ephemera_project: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    it "renders the form if it doesn't create a ephemera project" do
      post :create, params: { ephemera_project: invalid_params }
      expect(response).to render_template "valhalla/base/new"
    end
  end

  describe "index" do
    context "when they have permission" do
      let(:user) { FactoryGirl.create(:admin) }
      render_views
      it "has lists all ephemera projects" do
        FactoryGirl.create_for_repository(:ephemera_project)

        get :index
        expect(response.body).to have_content "Test Project"
      end
    end
  end

  describe "destroy" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        ephemera_project = FactoryGirl.create_for_repository(:ephemera_project)
        expect { delete :destroy, params: { id: ephemera_project.id.to_s } }.to raise_error CanCan::AccessDenied
      end
    end
    it "can delete a book" do
      ephemera_project = FactoryGirl.create_for_repository(:ephemera_project)
      delete :destroy, params: { id: ephemera_project.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: ephemera_project.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        ephemera_project = FactoryGirl.create_for_repository(:ephemera_project)

        expect { get :edit, params: { id: ephemera_project.id.to_s } }.to raise_error CanCan::AccessDenied
      end
    end
    context "when a ephemera project doesn't exist" do
      it "raises an error" do
        expect { get :edit, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        ephemera_project = FactoryGirl.create_for_repository(:ephemera_project)
        get :edit, params: { id: ephemera_project.id.to_s }

        expect(response.body).to have_field "Name", with: ephemera_project.name.first
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "update" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        ephemera_project = FactoryGirl.create_for_repository(:ephemera_project)

        expect { patch :update, params: { id: ephemera_project.id.to_s, ephemera_project: { name: ["Two"] } } }.to raise_error CanCan::AccessDenied
      end
    end
    context "when a ephemera project doesn't exist" do
      it "raises an error" do
        expect { patch :update, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        ephemera_project = FactoryGirl.create_for_repository(:ephemera_project)
        patch :update, params: { id: ephemera_project.id.to_s, ephemera_project: { name: ["Two"] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/id-#{ephemera_project.id}"
        id = response.location.gsub("http://test.host/catalog/id-", "")
        reloaded = find_resource(id)

        expect(reloaded.name).to eq ["Two"]
      end
      it "renders the form if it fails validations" do
        ephemera_project = FactoryGirl.create_for_repository(:ephemera_project)
        patch :update, params: { id: ephemera_project.id.to_s, ephemera_project: { name: nil } }

        expect(response).to render_template "valhalla/base/edit"
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
