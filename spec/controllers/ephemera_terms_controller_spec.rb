# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EphemeraTermsController do
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
      it "has a form for creating ephemera vocabularies" do
        FactoryGirl.create_for_repository(:ephemera_term)

        get :new
        expect(response.body).to have_field "Label"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "create" do
    let(:user) { FactoryGirl.create(:admin) }
    let(:valid_params) do
      {
        label: ['test label'],
        member_of_vocabulary_id: ['test id']
      }
    end
    let(:invalid_params) do
      {
        label: nil,
        member_of_vocabulary_id: nil
      }
    end
    context "when not an admin" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        expect { post :create, params: { ephemera_term: valid_params } }.to raise_error CanCan::AccessDenied
      end
    end
    it "can create an ephemera term" do
      post :create, params: { ephemera_term: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/").gsub(/^id-/, "")
      expect(find_resource(id).label).to contain_exactly "test label"
    end
    context "when something bad goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: { ephemera_term: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: { ephemera_term: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    it "renders the form if it doesn't create a ephemera term" do
      post :create, params: { ephemera_term: invalid_params }
      expect(response).to render_template "valhalla/base/new"
    end
  end

  describe "destroy" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        ephemera_term = FactoryGirl.create_for_repository(:ephemera_term)
        expect { delete :destroy, params: { id: ephemera_term.id.to_s } }.to raise_error CanCan::AccessDenied
      end
    end
    it "can delete a book" do
      ephemera_term = FactoryGirl.create_for_repository(:ephemera_term)
      delete :destroy, params: { id: ephemera_term.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: ephemera_term.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        ephemera_term = FactoryGirl.create_for_repository(:ephemera_term)

        expect { get :edit, params: { id: ephemera_term.id.to_s } }.to raise_error CanCan::AccessDenied
      end
    end
    context "when a ephemera term doesn't exist" do
      it "raises an error" do
        expect { get :edit, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        ephemera_term = FactoryGirl.create_for_repository(:ephemera_term)
        get :edit, params: { id: ephemera_term.id.to_s }

        expect(response.body).to have_field "Label", with: 'test term'
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "update" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        ephemera_term = FactoryGirl.create_for_repository(:ephemera_term)

        expect { patch :update, params: { id: ephemera_term.id.to_s, ephemera_term: { label: ["test label"], member_of_vocabulary_id: ["test id"] } } }.to raise_error CanCan::AccessDenied
      end
    end
    context "when a ephemera term doesn't exist" do
      it "raises an error" do
        expect { patch :update, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        ephemera_term = FactoryGirl.create_for_repository(:ephemera_term)
        patch :update, params: { id: ephemera_term.id.to_s, ephemera_term: { label: ["test label"], member_of_vocabulary_id: ["test id"] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/id-#{ephemera_term.id}"
        id = response.location.gsub("http://test.host/catalog/id-", "")
        reloaded = find_resource(id)

        expect(reloaded.label).to eq ["test label"]
      end
      it "renders the form if it fails validations" do
        ephemera_term = FactoryGirl.create_for_repository(:ephemera_term)
        patch :update, params: { id: ephemera_term.id.to_s, ephemera_term: { label: nil, member_of_vocabulary_id: nil } }

        expect(response).to render_template "valhalla/base/edit"
      end
    end
  end

  describe "index" do
    context "when they have permission" do
      let(:user) { FactoryGirl.create(:admin) }
      let(:vocab) { FactoryGirl.create_for_repository(:ephemera_vocabulary, label: 'test parent vocabulary') }
      render_views
      it "has lists all ephemera terms" do
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        res = FactoryGirl.build(:ephemera_term, label: 'test term', member_of_vocabulary_id: vocab.id)
        res.member_of_vocabulary_id = vocab.id
        term = adapter.persister.save(resource: res)

        get :index
        expect(response.body).to have_content term.label.first
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
