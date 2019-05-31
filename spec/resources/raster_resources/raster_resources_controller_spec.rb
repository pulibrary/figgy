# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe RasterResourcesController, type: :controller do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:resource_klass) { RasterResource }
  before do
    sign_in user if user
  end

  describe "new" do
    it_behaves_like "an access controlled new request"

    context "when logged in, with permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has a form for creating raster resources" do
        collection = FactoryBot.create_for_repository(:collection)
        parent = FactoryBot.create_for_repository(:raster_resource)

        get :new, params: { parent_id: parent.id.to_s }
        expect(response.body).to have_field "Title"
        expect(response.body).to have_field "Rights Statement"
        expect(response.body).to have_field "Rights Note"
        expect(response.body).to have_field "Local identifier"
        expect(response.body).to have_selector "#raster_resource_append_id[value='#{parent.id}']", visible: false
        expect(response.body).not_to have_select "Collections", name: "raster_resource[member_of_collection_ids][]", options: [collection.title.first]
        expect(response.body).to have_field "Place Name"
        expect(response.body).to have_field "Temporal"
        expect(response.body).to have_select "Rights Statement", name: "raster_resource[rights_statement]", options: [""] + ControlledVocabulary.for(:rights_statement).all.map(&:label)
        expect(response.body).to have_field "Cartographic scale"
        expect(response.body).to have_field "Cartographic projection"
        expect(response.body).to have_field "Held by"
        expect(response.body).to have_checked_field "Open"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "create" do
    let(:user) { FactoryBot.create(:admin) }
    let(:valid_params) do
      {
        title: ["Title 1", "Title 2"],
        rights_statement: RightsStatements.no_known_copyright.to_s,
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
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
    it "can create a raster resource" do
      post :create, params: { raster_resource: valid_params }

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
          title: ["Title 1", "Title 2"],
          rights_statement: RightsStatements.no_known_copyright.to_s,
          visibility: "restricted",
          member_of_collection_ids: [collection.id.to_s]
        }
      end
      let(:collection) { FactoryBot.create_for_repository(:collection) }
      it "works" do
        post :create, params: { raster_resource: valid_params }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
        expect(find_resource(id).member_of_collection_ids).to contain_exactly collection.id
      end
    end
    it "renders the form if it doesn't create a raster resource" do
      post :create, params: { raster_resource: invalid_params }
      expect(response).to render_template "base/new"
    end
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :raster_resource }
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a raster resource" do
      raster_resource = FactoryBot.create_for_repository(:raster_resource)
      delete :destroy, params: { id: raster_resource.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: raster_resource.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :raster_resource }
      it_behaves_like "an access controlled edit request"
    end
    context "when a raster resource doesn't exist" do
      it "raises an error" do
        get :edit, params: { id: "test" }
        expect(response).to redirect_to_not_found
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        raster_resource = FactoryBot.create_for_repository(:raster_resource)
        get :edit, params: { id: raster_resource.id.to_s }

        expect(response.body).to have_field "Title", with: raster_resource.title.first
        expect(response.body).to have_button "Save"
      end
    end
    context "when a raster resource has a fileset and child resources" do
      let(:file_metadata) { FileMetadata.new(use: [Valkyrie::Vocab::PCDMUse.OriginalFile], mime_type: "image/tiff; gdal-format=GTiff") }
      let(:file_set) { FactoryBot.create_for_repository(:file_set, title: "File", file_metadata: [file_metadata]) }
      let(:child_raster_resource) { FactoryBot.create_for_repository(:raster_resource, title: "Child Raster") }
      let(:child_vector_resource) { FactoryBot.create_for_repository(:vector_resource, title: "Child Vector") }

      render_views
      it "renders a drop-down to select thumbnail" do
        raster_resource = FactoryBot.create_for_repository(:raster_resource, member_ids: [child_raster_resource.id, file_set.id, child_vector_resource.id])
        get :edit, params: { id: raster_resource.id.to_s }

        expect(response.body).to have_select "Thumbnail", name: "raster_resource[thumbnail_id]", options: ["File", "Child Raster", "Child Vector"]
      end
    end
  end

  describe "update" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :raster_resource }
      let(:extra_params) { { raster_resource: { title: ["Two"] } } }
      it_behaves_like "an access controlled update request"
    end
    context "when a raster resource doesn't exist" do
      it "raises an error" do
        patch :update, params: { id: "test" }
        expect(response).to redirect_to_not_found
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        raster_resource = FactoryBot.create_for_repository(:raster_resource)
        patch :update, params: { id: raster_resource.id.to_s, raster_resource: { title: ["Two"] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/#{raster_resource.id}"
        id = response.location.gsub("http://test.host/catalog/", "")
        reloaded = find_resource(id)

        expect(reloaded.title).to eq ["Two"]
      end
      it "renders the form if it fails validations" do
        raster_resource = FactoryBot.create_for_repository(:raster_resource)
        patch :update, params: { id: raster_resource.id.to_s, raster_resource: { title: [""] } }

        expect(response).to render_template "base/edit"
      end
      it_behaves_like "a workflow controller", :raster_resource
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end

  describe "GET /raster_resources/:id/file_manager" do
    let(:user) { FactoryBot.create(:admin) }

    context "when an admin and with a geotiff" do
      let(:file_metadata) { FileMetadata.new(use: [Valkyrie::Vocab::PCDMUse.OriginalFile], mime_type: "image/tiff; gdal-format=GTiff") }

      it "sets the record and children variables" do
        child = FactoryBot.create_for_repository(:file_set, file_metadata: [file_metadata])
        parent = FactoryBot.create_for_repository(:raster_resource, member_ids: child.id)
        get :file_manager, params: { id: parent.id }

        expect(assigns(:change_set).id).to eq parent.id
        expect(assigns(:children).map(&:id)).to eq [child.id]
      end
    end
  end

  describe "GET /raster_resources/:id/geoblacklight" do
    let(:user) { FactoryBot.create(:admin) }
    let(:raster_resource) { FactoryBot.create_for_repository(:raster_resource) }
    let(:builder) { instance_double(GeoDiscovery::DocumentBuilder) }

    before do
      allow(GeoDiscovery::DocumentBuilder).to receive(:new).and_return(builder)
    end

    context "with a valid geoblacklight document" do
      before do
        allow(builder).to receive(:to_hash).and_return(id: "test")
      end

      it "renders the document" do
        get :geoblacklight, params: { id: raster_resource.id, format: :json }
        expect(response).to be_success
      end
    end
  end

  describe "#attach_to_parent" do
    let(:user) { FactoryBot.create(:admin) }
    let(:child) { FactoryBot.create_for_repository(:raster_resource) }
    let(:parent) { FactoryBot.create_for_repository(:scanned_map) }
    let(:params) do
      {
        id: child.id,
        parent_resource: { id: parent.id, member_ids: [child.id] }
      }
    end

    it "attaches a raster resource to any scanned map resource" do
      patch :attach_to_parent, params: params, format: :json

      expect(response.status).to eq(200)
      reloaded = find_resource(parent.id)
      expect(reloaded.member_ids.first.to_s).to eq child.id.to_s
    end
    context "with invalid parameter types" do
      let(:params) do
        {
          id: child.id,
          parent_resource: { id: parent.id, member_ids: nil }
        }
      end

      it "returns a bad request server response" do
        patch :attach_to_parent, params: params, format: :json
        expect(response.status).to eq 400
      end
    end
    context "with invalid parameters" do
      let(:params) do
        {
          id: child.id,
          parent_resource: { id: parent.id, member_ids: [], title: nil }
        }
      end

      it "returns a bad request server response" do
        patch :attach_to_parent, params: params, format: :json
        expect(response.status).to eq 400
      end
    end
    context "with an invalid parent ID" do
      let(:params) do
        {
          id: child.id,
          parent_resource: { id: "invalid", member_ids: [child.id] }
        }
      end

      it "returns a not found server response" do
        patch :attach_to_parent, params: params, format: :json
        expect(response.status).to eq 404
      end
    end
  end

  describe "#remove_from_parent" do
    let(:user) { FactoryBot.create(:admin) }
    let(:child) { FactoryBot.create_for_repository(:raster_resource) }
    let(:parent) { FactoryBot.create_for_repository(:scanned_map) }
    let(:params) do
      {
        id: child.id,
        parent_resource: { id: parent.id, member_ids: [child.id] }
      }
    end
    it "removes any raster resource attached to a given scanned map resource" do
      patch :remove_from_parent, params: params, format: :json

      expect(response.status).to eq(200)
      reloaded = find_resource(parent.id)
      expect(reloaded.member_ids).to be_empty
    end
    context "with invalid parameter types" do
      let(:params) do
        {
          id: child.id,
          parent_resource: { id: parent.id, member_ids: nil }
        }
      end

      it "returns a bad request server response" do
        patch :remove_from_parent, params: params, format: :json
        expect(response.status).to eq 400
      end
    end
    context "with invalid parameters" do
      let(:params) do
        {
          id: child.id,
          parent_resource: { id: parent.id, member_ids: [], title: nil }
        }
      end

      it "returns a bad request server response" do
        patch :remove_from_parent, params: params, format: :json
        expect(response.status).to eq 400
      end
    end
    context "with an invalid parent ID" do
      let(:params) do
        {
          id: child.id,
          parent_resource: { id: "invalid", member_ids: [child.id] }
        }
      end

      it "returns a not found server response" do
        patch :remove_from_parent, params: params, format: :json
        expect(response.status).to eq 404
      end
    end
  end

  describe "#attach_to_parent" do
    let(:user) { FactoryBot.create(:admin) }
    let(:parent_scanned_map) { FactoryBot.create_for_repository(:scanned_map) }
    let(:raster_resource) { FactoryBot.create_for_repository(:raster_resource) }

    it "appends an existing ScannedMap as a parent" do
      patch :attach_to_parent, params: {
        id: raster_resource.id.to_s, parent_resource: {
          id: parent_scanned_map.id.to_s, member_ids: [raster_resource.id.to_s]
        }
      }

      persisted = query_service.find_by(id: raster_resource.id)
      expect(persisted.decorate.scanned_map_parents).not_to be_empty
      expect(persisted.decorate.scanned_map_parents.first.id).to eq parent_scanned_map.id
    end
  end

  describe "#remove_from_parent" do
    let(:user) { FactoryBot.create(:admin) }
    let(:raster_resource) { FactoryBot.create_for_repository(:raster_resource) }

    context "when a RasterResource belongs to a ScannedMap parent" do
      it "removes an existing parent ScannedMap" do
        parent_scanned_map = FactoryBot.create_for_repository(:scanned_map, member_ids: [raster_resource.id])

        patch :remove_from_parent, params: {
          id: raster_resource.id.to_s, parent_resource: {
            id: parent_scanned_map.id.to_s, member_ids: [raster_resource.id.to_s]
          }
        }

        persisted = query_service.find_by(id: raster_resource.id)
        expect(persisted.decorate.scanned_map_parents).to be_empty
      end
    end
  end
end
