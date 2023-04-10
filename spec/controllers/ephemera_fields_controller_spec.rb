# frozen_string_literal: true
require "rails_helper"

RSpec.describe EphemeraFieldsController, type: :controller do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:ephemera_vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary) }
  let(:ephemera_field) { FactoryBot.create_for_repository(:ephemera_field, member_of_vocabulary_id: ephemera_vocabulary.id) }
  let(:ephemera_term) { FactoryBot.create_for_repository(:ephemera_term, member_of_vocabulary_id: ephemera_vocabulary.id) }
  before do
    sign_in user if user
  end

  describe "new" do
    it_behaves_like "an access controlled new request"

    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has a form for creating ephemera fields" do
        ephemera_term
        FactoryBot.create_for_repository(:ephemera_field)

        get :new
        expect(response.body).to have_field "Name"
        expect(response.body).not_to have_field "Favorite Terms"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "create" do
    let(:user) { FactoryBot.create(:admin) }
    let(:valid_params) do
      {
        field_name: ["test field"],
        member_of_vocabulary_id: [ephemera_vocabulary.id]
      }
    end
    let(:invalid_params) do
      {
        field_name: nil,
        member_of_vocabulary_id: nil
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
    it "can create an ephemera field" do
      post :create, params: { ephemera_field: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      expect(find_resource(id).field_name).to contain_exactly "test field"
    end
    context "when something bad goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: { ephemera_field: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all_of_model(model: EphemeraField).to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: { ephemera_field: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    it "renders the form if it doesn't create a ephemera field" do
      post :create, params: { ephemera_field: invalid_params }
      expect(response).to render_template "base/new"
    end
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_field }
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a book" do
      delete :destroy, params: { id: ephemera_field.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: ephemera_field.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_field }
      it_behaves_like "an access controlled edit request"
    end
    context "when a ephemera field doesn't exist" do
      it "raises an error" do
        get :edit, params: { id: "test" }
        expect(response).to have_http_status(404)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        ephemera_term
        get :edit, params: { id: ephemera_field.id.to_s }

        expect(response.body).to have_field "Name", with: "1"
        expect(response.body).to have_field "Favorite Terms"
        expect(response.body).to have_field "Rarely Used Terms"
        expect(response.body).to have_button "Save"
      end
    end
    context "when it has nested categories (like subjects)" do
      let(:ephemera_vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary) }
      let(:category) { FactoryBot.create_for_repository(:ephemera_vocabulary, member_of_vocabulary_id: ephemera_vocabulary.id) }
      let(:ephemera_field) { FactoryBot.create_for_repository(:ephemera_field, member_of_vocabulary_id: ephemera_vocabulary.id) }
      let(:ephemera_term) { FactoryBot.create_for_repository(:ephemera_term, member_of_vocabulary_id: category.id) }
      render_views
      it "renders a form with the subject" do
        ephemera_term
        get :edit, params: { id: ephemera_field.id.to_s }

        expect(response.body).to have_field "Name", with: "1"
        expect(response.body).to have_field "Favorite Terms"
        expect(response.body).to have_field "Rarely Used Terms"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "update" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_field }
      let(:extra_params) { { ephemera_field: { title: ["Two"] } } }
      it_behaves_like "an access controlled update request"
    end
    context "when a ephemera field doesn't exist" do
      it "raises an error" do
        patch :update, params: { id: "test" }
        expect(response).to have_http_status(404)
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        patch :update, params: { id: ephemera_field.id.to_s, ephemera_field: { field_name: ["test field2"], member_of_vocabulary_id: [ephemera_vocabulary.id] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/#{ephemera_field.id}"
        id = response.location.gsub("http://test.host/catalog/", "")
        reloaded = find_resource(id)

        expect(reloaded.field_name).to eq ["test field2"]
      end
      it "renders the form if it fails validations" do
        patch :update, params: { id: ephemera_field.id.to_s, ephemera_field: { field_name: nil, member_of_vocabulary_id: nil } }

        expect(response).to render_template "base/edit"
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
