# frozen_string_literal: true
require "rails_helper"
include FixtureFileUpload

RSpec.describe EphemeraVocabulariesController, type: :controller do
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
      it "has a form for creating ephemera vocabularies" do
        FactoryBot.create_for_repository(:ephemera_vocabulary)

        get :new
        expect(response.body).to have_field "Label"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "index" do
    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      let(:vocab) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "test parent vocabulary") }
      render_views
      it "has lists all ephemera vocabularies" do
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        res = FactoryBot.build(:ephemera_vocabulary, label: "test term", member_of_vocabulary_id: vocab.id)
        res.member_of_vocabulary_id = vocab.id
        child_vocab = adapter.persister.save(resource: res)

        get :index
        expect(response.body).to have_content vocab.label.first
        expect(response.body).to have_content child_vocab.label.first
      end
    end
  end

  describe "create" do
    let(:user) { FactoryBot.create(:admin) }
    let(:valid_params) do
      {
        label: ["test label"],
        value: ["test value"]
      }
    end
    let(:invalid_params) do
      {
        label: nil,
        value: nil
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
    it "can create an ephemera vocabulary" do
      post :create, params: { ephemera_vocabulary: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      expect(find_resource(id).label).to contain_exactly "test label"
    end
    context "when something bad goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: { ephemera_vocabulary: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: { ephemera_vocabulary: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    it "renders the form if it doesn't create a ephemera vocabulary" do
      post :create, params: { ephemera_vocabulary: invalid_params }
      expect(response).to render_template "ephemera_vocabularies/new"
    end
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_vocabulary }
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a book" do
      ephemera_vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary)
      delete :destroy, params: { id: ephemera_vocabulary.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: ephemera_vocabulary.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_vocabulary }
      it_behaves_like "an access controlled edit request"
    end
    context "when a ephemera vocabulary doesn't exist" do
      it "raises an error" do
        get :edit, params: { id: "test" }
        expect(response).to redirect_to_not_found
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        ephemera_vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary)
        get :edit, params: { id: ephemera_vocabulary.id.to_s }

        expect(response.body).to have_field "Label", with: "test vocabulary"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "update" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_vocabulary }
      let(:extra_params) { { ephemera_vocabulary: { label: ["test label"], value: ["test value"] } } }
      it_behaves_like "an access controlled update request"
    end
    context "when a ephemera vocabulary doesn't exist" do
      it "raises an error" do
        patch :update, params: { id: "test" }
        expect(response).to redirect_to_not_found
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        ephemera_vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary)
        patch :update, params: { id: ephemera_vocabulary.id.to_s, ephemera_vocabulary: { label: ["test label"], value: ["test value"] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/#{ephemera_vocabulary.id}"
        id = response.location.gsub("http://test.host/catalog/", "")
        reloaded = find_resource(id)

        expect(reloaded.label).to eq ["test label"]
      end
      it "renders the form if it fails validations" do
        ephemera_vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary)
        patch :update, params: { id: ephemera_vocabulary.id.to_s, ephemera_vocabulary: { label: nil, value: nil } }

        expect(response).to render_template "base/edit"
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
