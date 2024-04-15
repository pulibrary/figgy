# frozen_string_literal: true
require "rails_helper"

RSpec.describe ScannedMapsController, type: :controller do
  include Rails.application.routes.url_helpers

  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  before do
    sign_in user if user
  end

  describe "new" do
    it_behaves_like "an access controlled new request"

    context "when not logged in but an auth token is given" do
      it "renders the full manifest" do
        resource = FactoryBot.create_for_repository(:complete_campus_only_scanned_map)
        authorization_token = AuthToken.create!(group: ["admin"], label: "Administration Token")
        get :manifest, params: { id: resource.id, format: :json, auth_token: authorization_token.token }

        expect(response).to be_successful
        expect(response.body).not_to eq "{}"
      end
    end
    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has a form for creating map images" do
        collection = FactoryBot.create_for_repository(:collection)
        parent = FactoryBot.create_for_repository(:scanned_map)

        get :new, params: { parent_id: parent.id.to_s }
        expect(response.body).to have_field "Title"
        expect(response.body).to have_field "Source Metadata ID"
        expect(response.body).to have_field "scanned_map[refresh_remote_metadata]"
        expect(response.body).to have_field "Rights Statement"
        expect(response.body).to have_field "Rights Note"
        expect(response.body).to have_field "Local identifier"
        expect(response.body).to have_selector "#scanned_map_append_id[value='#{parent.id}']", visible: false
        expect(response.body).not_to have_select "Collections", name: "scanned_map[member_of_collection_ids][]", options: [collection.title.first]
        expect(response.body).to have_field "Place Name"
        expect(response.body).to have_field "Temporal"
        expect(response.body).to have_select "Rights Statement", name: "scanned_map[rights_statement]", options: [""] + ControlledVocabulary.for(:rights_statement).all.map(&:label)
        expect(response.body).to have_field "Cartographic scale"
        expect(response.body).to have_field "Held by"
        expect(response.body).to have_checked_field "Open"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "create" do
    let(:user) { FactoryBot.create(:admin) }
    let(:rights_statement) { RightsStatements.no_known_copyright }
    let(:valid_params) do
      {
        title: ["Title 1", "Title 2"],
        rights_statement: rights_statement,
        visibility: "restricted"
      }
    end
    let(:invalid_params) do
      {
        title: [""],
        rights_statement: rights_statement,
        visibility: "restricted"
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
    it "can create a map image" do
      post :create, params: { scanned_map: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      expect(find_resource(id).title).to contain_exactly "Title 1", "Title 2"
    end
    context "when joining a collection" do
      let(:valid_params) do
        {
          title: ["Title 1", "Title 2"],
          rights_statement: rights_statement,
          visibility: "restricted",
          member_of_collection_ids: [collection.id.to_s]
        }
      end
      let(:collection) { FactoryBot.create_for_repository(:collection) }
      it "works" do
        post :create, params: { scanned_map: valid_params }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
        expect(find_resource(id).member_of_collection_ids).to contain_exactly collection.id
      end
    end
    context "when something goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: { scanned_map: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: { scanned_map: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    context "when importing remote metadata" do
      let(:coverage) { GeoCoverage.new(43.039, -69.856, 42.943, -71.032) }
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      let(:params) do
        {
          source_metadata_identifier: "9951446203506421",
          coverage: coverage.to_s,
          rights_statement: rights_statement,
          visibility: visibility
        }
      end

      before do
        stub_catalog(bib_id: "9951446203506421")
      end

      it "generates a resource with a valid geoblacklight document" do
        post :create, params: { scanned_map: params }

        id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
        resource = find_resource(id)
        builder = GeoDiscovery::DocumentBuilder.new(resource, GeoDiscovery::GeoblacklightDocument.new)
        expect(builder.to_hash[:dc_title_s]).to eq "Mount Holly, N.J. [map]."
      end
    end
    it "renders the form if it doesn't create a map image" do
      post :create, params: { scanned_map: invalid_params }
      expect(response).to render_template "base/new"
    end
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :scanned_map }
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a book" do
      scanned_map = FactoryBot.create_for_repository(:scanned_map)
      delete :destroy, params: { id: scanned_map.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: scanned_map.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :scanned_map }
      it_behaves_like "an access controlled edit request"
    end
    context "when a map image doesn't exist" do
      it "raises an error" do
        get :edit, params: { id: "test" }
        expect(response).to have_http_status(404)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        scanned_map = FactoryBot.create_for_repository(:scanned_map)
        get :edit, params: { id: scanned_map.id.to_s }

        expect(response.body).to have_field "Title", with: scanned_map.title.first
        expect(response.body).to have_button "Save"
      end
    end
    context "when a scanned map has a fileset and a child resource" do
      let(:file_metadata) { FileMetadata.new(use: [Valkyrie::Vocab::PCDMUse.OriginalFile], mime_type: "image/tiff") }
      let(:file_set) { FactoryBot.create_for_repository(:file_set, title: "File", file_metadata: [file_metadata]) }
      let(:child_scanned_map) { FactoryBot.create_for_repository(:scanned_map, title: "Child Scanned Map") }

      render_views
      it "renders a drop-down to select thumbnail" do
        scanned_map = FactoryBot.create_for_repository(:scanned_map, member_ids: [file_set.id, child_scanned_map.id])
        get :edit, params: { id: scanned_map.id.to_s }

        expect(response.body).to have_select "Thumbnail", name: "scanned_map[thumbnail_id]", options: ["File", "Child Scanned Map"]
      end
    end
  end

  describe "update" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :scanned_map }
      let(:extra_params) { { scanned_map: { title: ["Two"] } } }
      it_behaves_like "an access controlled update request"
    end
    context "when a map image doesn't exist" do
      it "raises an error" do
        patch :update, params: { id: "test" }
        expect(response).to have_http_status(404)
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        scanned_map = FactoryBot.create_for_repository(:scanned_map)
        patch :update, params: { id: scanned_map.id.to_s, scanned_map: { title: ["Two"] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/#{scanned_map.id}"
        id = response.location.gsub("http://test.host/catalog/", "")
        reloaded = find_resource(id)

        expect(reloaded.title).to eq ["Two"]
      end
      it "renders the form if it fails validations" do
        scanned_map = FactoryBot.create_for_repository(:scanned_map)
        patch :update, params: { id: scanned_map.id.to_s, scanned_map: { title: [""] } }

        expect(response).to render_template "base/edit"
      end
      it_behaves_like "a workflow controller", :scanned_map
    end
  end

  describe "struct_manager" do
    let(:user) { FactoryBot.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "redirects to login or root" do
        scanned_map = FactoryBot.create_for_repository(:scanned_map)

        get :struct_manager, params: { id: scanned_map.id.to_s }
        expect(response).to be_redirect
      end
    end
    context "when a map image doesn't exist" do
      it "raises an error" do
        get :struct_manager, params: { id: "banana" }
        expect(response).to have_http_status(404)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a structure editor form" do
        file_set1 = FactoryBot.create_for_repository(:file_set)
        file_set2 = FactoryBot.create_for_repository(:geo_image_file_set)
        child_scanned_map = FactoryBot.create_for_repository(
          :scanned_map,
          member_ids: file_set2.id
        )
        scanned_map = FactoryBot.create_for_repository(
          :scanned_map,
          member_ids: [file_set1.id, child_scanned_map.id],
          logical_structure: [
            { label: "testing", nodes: [{ label: "Chapter 1", nodes: [{ proxy: file_set1.id }] }] }
          ]
        )

        get :struct_manager, params: { id: scanned_map.id.to_s }
        expect(response.body).to have_selector "li[data-proxy='#{file_set1.id}']"
        expect(response.body).to have_selector "li[data-proxy='#{file_set2.id}']"
        expect(response.body).to have_field("label", with: "Chapter 1")
        expect(response.body).to have_link scanned_map.title.first, href: solr_document_path(id: scanned_map.id)
      end
    end
  end

  describe "structure" do
    let(:user) { FactoryBot.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "redirects to login or root" do
        scanned_map = FactoryBot.create_for_repository(:scanned_map)

        get :structure, params: { id: scanned_map.id.to_s }
        expect(response).to be_redirect
      end
    end
    context "when a map image doesn't exist" do
      it "raises an error" do
        get :structure, params: { id: "banana" }
        expect(response).to have_http_status(404)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a structure editor form" do
        file_set1 = FactoryBot.create_for_repository(:file_set)
        file_set2 = FactoryBot.create_for_repository(:geo_image_file_set)
        child_scanned_map = FactoryBot.create_for_repository(
          :scanned_map,
          member_ids: file_set2.id
        )
        scanned_map = FactoryBot.create_for_repository(
          :scanned_map,
          member_ids: [file_set1.id, child_scanned_map.id],
          logical_structure: [
            { label: "testing", nodes: [{ label: "Chapter 1", nodes: [{ proxy: file_set1.id }] }] }
          ]
        )

        get :structure, params: { id: scanned_map.id.to_s }
        expect(response.body).to have_selector "struct-manager"
        expect(response.body).to have_link scanned_map.title.first, href: solr_document_path(id: scanned_map.id)
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end

  describe "GET /scanned_maps/:id/file_manager" do
    let(:user) { FactoryBot.create(:admin) }

    context "when an admin and with an image file" do
      let(:file_metadata) { FileMetadata.new(use: [Valkyrie::Vocab::PCDMUse.OriginalFile], mime_type: "image/tiff") }

      it "sets the record and children variables" do
        child = FactoryBot.create_for_repository(:file_set, file_metadata: [file_metadata])
        parent = FactoryBot.create_for_repository(:scanned_map, member_ids: child.id)
        get :file_manager, params: { id: parent.id }

        expect(assigns(:change_set).id).to eq parent.id
        expect(assigns(:children).map(&:id)).to eq [child.id]
      end
    end
  end

  describe "GET /concern/scanned_maps/:id/manifest" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    before do
      stub_ezid
    end
    it "returns a IIIF manifest for a resource with a file" do
      scanned_map = FactoryBot.create_for_repository(:complete_scanned_map, files: [file])

      get :manifest, params: { id: scanned_map.id.to_s, format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:sequences].length).to eq 1
      expect(manifest_response[:viewingHint]).to eq "individuals"
    end
  end

  # Tests functionality defined in `app/controllers/concerns/geo_resource_controller.rb`
  #   Acts as a global spec in this regard
  describe "PUT /concern/scanned_maps/:id/extract_metadata/:file_set_id" do
    with_queue_adapter :inline
    let(:user) { FactoryBot.create(:admin) }
    let(:file) { fixture_file_upload("files/geo_metadata/fgdc.xml", "application/xml") }
    let(:tika_output) { tika_xml_output }

    it "extracts fgdc metadata into scanned map" do
      scanned_map = FactoryBot.create_for_repository(:scanned_map, files: [file])

      put :extract_metadata, params: { id: scanned_map.id.to_s, file_set_id: scanned_map.member_ids.first.to_s }
      expect(query_service.find_by(id: scanned_map.id).title).to eq ["China census data by county, 2000-2010"]
    end
  end

  describe "#remove_from_parent" do
    let(:user) { FactoryBot.create(:admin) }
    let(:scanned_map) { FactoryBot.create_for_repository(:scanned_map) }
    let(:sibling_resource) { FactoryBot.create_for_repository(:scanned_map) }

    context "when a ScannedMap belongs to a ScannedMap parent" do
      it "removes an existing parent ScannedMap, retaining its other children" do
        parent_scanned_map = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map.id, sibling_resource.id])

        patch :remove_from_parent, params: {
          id: scanned_map.id.to_s,
          parent_resource: {
            id: parent_scanned_map.id.to_s
          }
        }

        persisted = query_service.find_by(id: scanned_map.id)
        expect(persisted.decorate.decorated_scanned_map_parents).to be_empty
        parent = query_service.find_by(id: parent_scanned_map.id)
        expect(Wayfinder.for(parent).members.map(&:id)).to eq [sibling_resource.id]
      end
    end
  end
end
