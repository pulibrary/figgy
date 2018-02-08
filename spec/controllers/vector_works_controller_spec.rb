# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe VectorWorksController do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  before do
    sign_in user if user
  end

  describe "new" do
    it_behaves_like "an access controlled new request"

    context "when logged in, with permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has a form for creating vector works" do
        collection = FactoryBot.create_for_repository(:collection)
        # TODO: look at what create_for_repository actually does
        parent = FactoryBot.create_for_repository(:vector_work)

        get :new, params: { parent_id: parent.id.to_s }
        expect(response.body).to have_field "Title"
        expect(response.body).to have_field "Rights Statement"
        expect(response.body).to have_field "Rights Note"
        expect(response.body).to have_field "Local identifier"
        expect(response.body).to have_selector "#vector_work_append_id[value='#{parent.id}']", visible: false
        expect(response.body).to have_select "Collections", name: "vector_work[member_of_collection_ids][]", options: [collection.title.first]
        expect(response.body).to have_field "Spatial"
        expect(response.body).to have_field "Temporal"
        expect(response.body).to have_select "Rights Statement", name: "vector_work[rights_statement]", options: [""] + ControlledVocabulary.for(:rights_statement).all.map(&:label)
        expect(response.body).to have_field "Cartographic scale"
        expect(response.body).to have_field "Cartographic projection"
        expect(response.body).to have_checked_field "Open"
        expect(response.body).to have_button "Save"
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
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
    it "can create a vector work" do
      post :create, params: { vector_work: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      resource = find_resource(id)
      expect(resource.title).to contain_exactly "Title 1", "Title 2"
      expect(resource.depositor).to eq [user.uid]
    end
    context "when joining a collection" do
      let(:valid_params) do
        {
          title: ['Title 1', 'Title 2'],
          rights_statement: 'Test Statement',
          visibility: 'restricted',
          member_of_collection_ids: [collection.id.to_s]
        }
      end
      let(:collection) { FactoryBot.create_for_repository(:collection) }
      it "works" do
        post :create, params: { vector_work: valid_params }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
        expect(find_resource(id).member_of_collection_ids).to contain_exactly collection.id
      end
    end
    # TODO: Do we need this in multiple tests?
    context "when something goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: { vector_work: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: { vector_work: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    it "renders the form if it doesn't create a vector work" do
      post :create, params: { vector_work: invalid_params }
      expect(response).to render_template "valhalla/base/new"
    end
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :vector_work }
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a book" do
      vector_work = FactoryBot.create_for_repository(:vector_work)
      delete :destroy, params: { id: vector_work.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: vector_work.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :vector_work }
      it_behaves_like "an access controlled edit request"
    end
    context "when a vector work doesn't exist" do
      it "raises an error" do
        expect { get :edit, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        vector_work = FactoryBot.create_for_repository(:vector_work)
        get :edit, params: { id: vector_work.id.to_s }

        expect(response.body).to have_field "Title", with: vector_work.title.first
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "update" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :vector_work }
      let(:extra_params) { { vector_work: { title: ["Two"] } } }
      it_behaves_like "an access controlled update request"
    end
    context "when a vector work doesn't exist" do
      it "raises an error" do
        expect { patch :update, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        vector_work = FactoryBot.create_for_repository(:vector_work)
        patch :update, params: { id: vector_work.id.to_s, vector_work: { title: ["Two"] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/#{vector_work.id}"
        id = response.location.gsub("http://test.host/catalog/", "")
        reloaded = find_resource(id)

        expect(reloaded.title).to eq ["Two"]
      end
      it "renders the form if it fails validations" do
        vector_work = FactoryBot.create_for_repository(:vector_work)
        patch :update, params: { id: vector_work.id.to_s, vector_work: { title: [""] } }

        expect(response).to render_template "valhalla/base/edit"
      end
      it_behaves_like "a workflow controller", :vector_work
    end
  end

  # TODO: move to spec helper?
  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end

  describe "GET /vector_works/:id/file_manager" do
    let(:user) { FactoryBot.create(:admin) }

    context "when an admin and with a shapefile" do
      let(:file_metadata) { FileMetadata.new(use: [Valkyrie::Vocab::PCDMUse.OriginalFile], mime_type: 'application/zip; ogr-format="ESRI Shapefile"') }

      it "sets the record and children variables" do
        child = FactoryBot.create_for_repository(:file_set, file_metadata: [file_metadata])
        parent = FactoryBot.create_for_repository(:vector_work, member_ids: child.id)
        get :file_manager, params: { id: parent.id }

        expect(assigns(:change_set).id).to eq parent.id
        expect(assigns(:children).map(&:id)).to eq [child.id]
      end
    end

    context "when an admin and with an fgdc metadata file" do
      let(:file_metadata) { FileMetadata.new(use: [Valkyrie::Vocab::PCDMUse.OriginalFile], mime_type: 'application/xml; schema=fgdc') }

      it "sets the record and metadata children variables" do
        child = FactoryBot.create_for_repository(:file_set, file_metadata: [file_metadata])
        parent = FactoryBot.create_for_repository(:vector_work, member_ids: child.id)
        get :file_manager, params: { id: parent.id }

        expect(assigns(:change_set).id).to eq parent.id
        expect(assigns(:metadata_children).map(&:id)).to eq [child.id]
      end
    end
  end

  describe "GET /vector_works/:id/geoblacklight" do
    let(:user) { FactoryBot.create(:admin) }
    let(:vector_work) { FactoryBot.create_for_repository(:vector_work) }
    let(:builder) { instance_double(GeoResources::Discovery::DocumentBuilder) }

    before do
      allow(GeoResources::Discovery::DocumentBuilder).to receive(:new).and_return(builder)
    end

    context 'with a valid geoblacklight document' do
      before do
        allow(builder).to receive(:to_hash).and_return(id: 'test')
      end

      it 'renders the document' do
        get :geoblacklight, params: { id: vector_work.id, format: :json }
        expect(response).to be_success
      end
    end

    context 'with an invalid geoblacklight document' do
      before do
        allow(builder).to receive(:to_hash).and_return(error: 'problem')
      end

      it 'returns an error message' do
        get :geoblacklight, params: { id: vector_work.id, format: :json }
        expect(response.body).to include('problem')
      end
    end
  end
end
