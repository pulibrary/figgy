# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe ScannedResourcesController do
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
        resource = FactoryBot.create_for_repository(:complete_campus_only_scanned_resource)
        authorization_token = AuthToken.create!(group: ["admin"], label: "Admin Token")
        get :manifest, params: { id: resource.id, format: :json, auth_token: authorization_token.token }

        expect(response).to be_success
        expect(response.body).not_to eq "{}"
      end
    end
    context "when not logged in" do
      it "returns a 404" do
        resource = FactoryBot.create_for_repository(:complete_campus_only_scanned_resource)
        get :manifest, params: { id: resource.id, format: :json }

        expect(response).to be_not_found
      end
    end
    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has a form for creating scanned resources" do
        collection = FactoryBot.create_for_repository(:collection)
        parent = FactoryBot.create_for_repository(:scanned_resource)

        get :new, params: { parent_id: parent.id.to_s }
        expect(response.body).to have_field "Title"
        expect(response.body).to have_field "Source Metadata ID"
        expect(response.body).to have_field "scanned_resource[refresh_remote_metadata]"
        expect(response.body).to have_field "Rights Statement"
        expect(response.body).to have_field "Rights Note"
        expect(response.body).to have_field "Local identifier"
        expect(response.body).to have_field "Holding Location"
        expect(response.body).to have_field "Portion Note"
        expect(response.body).to have_field "Navigation Date", class: "timepicker"
        expect(response.body).to have_selector "#scanned_resource_append_id[value='#{parent.id}']", visible: false
        expect(response.body).to have_select "Collections", name: "scanned_resource[member_of_collection_ids][]", options: [collection.title.first]
        expect(response.body).to have_select "Rights Statement", name: "scanned_resource[rights_statement]", options: [""] + ControlledVocabulary.for(:rights_statement).all.map(&:label)
        expect(response.body).to have_select "PDF Type", name: "scanned_resource[pdf_type]", options: ["Color PDF", "Grayscale PDF", "Bitonal PDF", "No PDF"]
        expect(response.body).to have_select "Holding Location", name: "scanned_resource[holding_location]", options: [""] + ControlledVocabulary.for(:holding_location).all.map(&:label)
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
    it "can create a scanned resource" do
      post :create, params: { scanned_resource: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      resource = find_resource(id)
      expect(resource.title).to contain_exactly "Title 1", "Title 2"
      expect(resource.depositor).to eq [user.uid]
    end
    it "can create a nested scanned resource" do
      parent = FactoryBot.create_for_repository(:scanned_resource)
      post :create, params: { scanned_resource: valid_params.merge(append_id: parent.id.to_s) }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/parent/#{parent.id}/"
      id = response.location.gsub("http://test.host/catalog/parent/#{parent.id}/", "")
      expect(find_resource(id).title).to contain_exactly "Title 1", "Title 2"
      expect(find_resource(parent.id).member_ids).to eq [Valkyrie::ID.new(id)]
      solr_record = Blacklight.default_index.connection.get("select", params: { qt: "document", q: "id:#{id}" })["response"]["docs"][0]
      expect(solr_record["member_of_ssim"]).to eq ["id-#{parent.id}"]
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
        post :create, params: { scanned_resource: valid_params }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
        expect(find_resource(id).member_of_collection_ids).to contain_exactly collection.id
      end
    end
    context "when something bad goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: { scanned_resource: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: { scanned_resource: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    it "renders the form if it doesn't create a scanned resource" do
      post :create, params: { scanned_resource: invalid_params }
      expect(response).to render_template "valhalla/base/new"
    end
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :scanned_resource }
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a book" do
      scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
      delete :destroy, params: { id: scanned_resource.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: scanned_resource.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :scanned_resource }
      it_behaves_like "an access controlled edit request"
    end
    context "when a scanned resource doesn't exist" do
      it "raises an error" do
        expect { get :edit, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
        get :edit, params: { id: scanned_resource.id.to_s }

        expect(response.body).to have_field "Title", with: scanned_resource.title.first
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "access control" do
      let(:factory) { :scanned_resource }
      let(:extra_params) { { scanned_resource: { title: ["Two"] } } }
      it_behaves_like "an access controlled update request"
    end
    context "when a scanned resource doesn't exist" do
      it "raises an error" do
        expect { patch :update, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
        patch :update, params: { id: scanned_resource.id.to_s, scanned_resource: { title: ["Two"] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/#{scanned_resource.id}"
        id = response.location.gsub("http://test.host/catalog/", "")
        reloaded = find_resource(id)

        expect(reloaded.title).to eq ["Two"]
      end
      it "renders the form if it fails validations" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
        patch :update, params: { id: scanned_resource.id.to_s, scanned_resource: { title: [""] } }

        expect(response).to render_template "valhalla/base/edit"
      end
      it_behaves_like "a workflow controller", :scanned_resource
    end
  end

  describe "json update" do
    let(:user) { FactoryBot.create(:admin) }

    context "when not an admin" do
      let(:user) { FactoryBot.create(:user) }
      it "returns 404" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        params = { id: resource.id.to_s, scanned_resource: { member_ids: ["not_an_id"] }, format: :json }
        patch :update, params: params
        expect(response.status).to eq(404)
      end
    end

    context "when a scanned resource doesn't exist" do
      it "returns 404" do
        patch :update, params: { id: "not_an_id", format: :json }
        expect(response.status).to eq(404)
      end
    end

    context "when the scanned resource does exist" do
      it "returns 400 for invalid data" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
        params = { id: scanned_resource.id.to_s, scanned_resource: { title: [""] }, format: :json }
        patch :update, params: params
        expect(response.status).to eq(400)
      end
      it "updates and returns 200 for valid data" do
        file_set1 = FactoryBot.create_for_repository(:file_set)
        file_set2 = FactoryBot.create_for_repository(:file_set)
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [file_set1.id, file_set2.id])

        params = { id: scanned_resource.id.to_s, scanned_resource: { member_ids: [file_set2.id, file_set1.id] }, format: :json }
        patch :update, params: params
        expect(response.status).to eq(200)
        reloaded = find_resource(scanned_resource.id)
        expect(reloaded.member_ids.first.to_s).to eq file_set2.id.to_s
      end
    end
  end

  describe "structure" do
    let(:user) { FactoryBot.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "redirects to login or root" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)

        get :structure, params: { id: scanned_resource.id.to_s }
        expect(response).to be_redirect
      end
    end
    context "when a scanned resource doesn't exist" do
      it "raises an error" do
        expect { get :structure, params: { id: "banana" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a structure editor form" do
        file_set = FactoryBot.create_for_repository(:file_set)
        scanned_resource = FactoryBot.create_for_repository(
          :scanned_resource,
          member_ids: file_set.id,
          logical_structure: [
            { label: 'testing', nodes: [{ label: 'Chapter 1', nodes: [{ proxy: file_set.id }] }] }
          ]
        )

        get :structure, params: { id: scanned_resource.id.to_s }

        expect(response.body).to have_selector "li[data-proxy='#{file_set.id}']"
        expect(response.body).to have_field('label', with: 'Chapter 1')
        expect(response.body).to have_link scanned_resource.title.first, href: solr_document_path(id: scanned_resource.id)
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end

  context "when an admin" do
    let(:user) { FactoryBot.create(:admin) }
    describe "GET /scanned_resources/:id/file_manager" do
      it "sets the record and children variables" do
        child = FactoryBot.create_for_repository(:file_set)
        parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: child.id)

        get :file_manager, params: { id: parent.id }

        expect(assigns(:change_set).id).to eq parent.id
        expect(assigns(:children).map(&:id)).to eq [child.id]
      end
    end

    # This block tests functionality defined in `app/controllers/concerns/browse_everythingable.rb`
    #   Acts as a 'master spec' in this regard
    describe "POST /concern/scanned_resources/:id/browse_everything_files" do
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
        resource = FactoryBot.create_for_repository(:scanned_resource)
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
        resource = FactoryBot.create_for_repository(:scanned_resource)
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

  describe "GET /concern/scanned_resources/:id/manifest" do
    let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
    it "returns a IIIF manifest for a resource with a file" do
      scanned_resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])

      get :manifest, params: { id: scanned_resource.id.to_s, format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:sequences].length).to eq 1
      expect(manifest_response[:viewingHint]).to eq "individuals"
    end
  end

  describe "GET /concern/scanned_resources/:id/pdf" do
    let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
    let(:file_set) { scanned_resource.member_ids.first }
    before do
      stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,287/0/grey.jpg")
        .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
    end
    it "generates a PDF, attaches it to the SR, and redirects to download for it" do
      get :pdf, params: { id: scanned_resource.id.to_s }
      reloaded = adapter.query_service.find_by(id: scanned_resource.id)

      expect(reloaded.file_metadata).not_to be_blank
      expect(reloaded.pdf_file).not_to be_blank
      expect(response).to redirect_to Valhalla::Engine.routes.url_helpers.download_path(resource_id: scanned_resource.id.to_s, id: reloaded.pdf_file.id.to_s)
    end
  end
end
