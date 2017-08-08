# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe MultiVolumeWorksController do
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
      it "has a form for creating Multi Volume Works" do
        collection = FactoryGirl.create_for_repository(:collection)

        get :new
        expect(response.body).to have_field "Title"
        expect(response.body).to have_field "Source Metadata ID"
        expect(response.body).to have_field "multi_volume_work[refresh_remote_metadata]"
        expect(response.body).to have_field "Rights Statement"
        expect(response.body).to have_field "Rights Note"
        expect(response.body).to have_field "Local identifier"
        expect(response.body).to have_field "Holding Location"
        expect(response.body).to have_field "Portion Note"
        expect(response.body).to have_field "Navigation Date"
        expect(response.body).to have_select "Collections", name: "multi_volume_work[member_of_collection_ids][]", options: ["", collection.title.first]
        expect(response.body).to have_select "Rights Statement", name: "multi_volume_work[rights_statement]", options: [""] + ControlledVocabulary.for(:rights_statement).all.map(&:label)
        expect(response.body).to have_select "PDF Type", name: "multi_volume_work[pdf_type]", options: ["Color PDF", "Grayscale PDF", "Bitonal PDF", "No PDF"]
        expect(response.body).to have_select "Holding Location", name: "multi_volume_work[holding_location]", options: [""] + ControlledVocabulary.for(:holding_location).all.map(&:label)
        expect(response.body).to have_checked_field "Private"
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "create" do
    let(:user) { FactoryGirl.create(:admin) }
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
    context "when not an admin" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        expect { post :create, params: { multi_volume_work: valid_params } }.to raise_error CanCan::AccessDenied
      end
    end
    it "can create a multi volume work" do
      post :create, params: { multi_volume_work: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/").gsub(/^id-/, "")
      expect(find_resource(id).title).to contain_exactly "Title 1", "Title 2"
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
      let(:collection) { FactoryGirl.create_for_repository(:collection) }
      it "works" do
        post :create, params: { multi_volume_work: valid_params }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/").gsub(/^id-/, "")
        expect(find_resource(id).member_of_collection_ids).to contain_exactly collection.id
      end
    end
    it "renders the form if it doesn't create a MVW" do
      post :create, params: { multi_volume_work: invalid_params }
      expect(response).to render_template "valhalla/base/new"
    end
  end

  describe "destroy" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        multi_volume_work = FactoryGirl.create_for_repository(:multi_volume_work)
        expect { delete :destroy, params: { id: multi_volume_work.id.to_s } }.to raise_error CanCan::AccessDenied
      end
    end
    it "can delete a MVW" do
      multi_volume_work = FactoryGirl.create_for_repository(:multi_volume_work)
      delete :destroy, params: { id: multi_volume_work.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: multi_volume_work.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        multi_volume_work = FactoryGirl.create_for_repository(:multi_volume_work)

        expect { get :edit, params: { id: multi_volume_work.id.to_s } }.to raise_error CanCan::AccessDenied
      end
    end
    context "when a MVW doesn't exist" do
      it "raises an error" do
        expect { get :edit, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        multi_volume_work = FactoryGirl.create_for_repository(:multi_volume_work)
        get :edit, params: { id: multi_volume_work.id.to_s }

        expect(response.body).to have_field "Title", with: multi_volume_work.title.first
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "update" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        multi_volume_work = FactoryGirl.create_for_repository(:multi_volume_work)

        expect { patch :update, params: { id: multi_volume_work.id.to_s, multi_volume_work: { title: ["Two"] } } }.to raise_error CanCan::AccessDenied
      end
    end
    context "when a scanned resource doesn't exist" do
      it "raises an error" do
        expect { patch :update, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        multi_volume_work = FactoryGirl.create_for_repository(:multi_volume_work)
        patch :update, params: { id: multi_volume_work.id.to_s, multi_volume_work: { title: ["Two"] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/id-#{multi_volume_work.id}"
        id = response.location.gsub("http://test.host/catalog/id-", "")
        reloaded = find_resource(id)

        expect(reloaded.title).to eq ["Two"]
      end
      it "renders the form if it fails validations" do
        multi_volume_work = FactoryGirl.create_for_repository(:multi_volume_work)
        patch :update, params: { id: multi_volume_work.id.to_s, multi_volume_work: { title: [""] } }

        expect(response).to render_template "valhalla/base/edit"
      end
    end
  end

  describe "structure" do
    let(:user) { FactoryGirl.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        multi_volume_work = FactoryGirl.create_for_repository(:multi_volume_work)

        expect { get :structure, params: { id: multi_volume_work.id.to_s } }.to raise_error CanCan::AccessDenied
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
        scanned_resource = FactoryGirl.create_for_repository(:scanned_resource)
        multi_volume_work = FactoryGirl.create_for_repository(
          :multi_volume_work,
          member_ids: scanned_resource.id,
          logical_structure: [
            { label: 'testing', nodes: [{ label: 'Chapter 1', nodes: [{ proxy: scanned_resource.id }] }] }
          ]
        )

        get :structure, params: { id: multi_volume_work.id.to_s }

        expect(response.body).to have_selector "li[data-proxy='#{scanned_resource.id}']"
        expect(response.body).to have_field('label', with: 'Chapter 1')
        expect(response.body).to have_link multi_volume_work.title.first, href: solr_document_path(id: "id-#{multi_volume_work.id}")
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end

  context "when an admin" do
    let(:user) { FactoryGirl.create(:admin) }
    describe "GET /multi_volume_works/:id/file_manager" do
      render_views
      it "sets the record and children variables" do
        child = FactoryGirl.create_for_repository(:scanned_resource)
        parent = FactoryGirl.create_for_repository(:multi_volume_work, member_ids: child.id)

        get :file_manager, params: { id: parent.id }

        expect(assigns(:change_set).id).to eq parent.id
        expect(assigns(:children).map(&:id)).to eq [child.id]
      end
    end

    describe "POST /concern/multi_volume_works/:id/browse_everything_files" do
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
        resource = FactoryGirl.create_for_repository(:multi_volume_work)
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
        resource = FactoryGirl.create_for_repository(:multi_volume_work)
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
      scanned_resource = FactoryGirl.create_for_repository(:scanned_resource, files: [file])

      get :manifest, params: { id: scanned_resource.id.to_s, format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:sequences].length).to eq 1
    end
  end
end
