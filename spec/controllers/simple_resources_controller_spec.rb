# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SimpleResourcesController do
  with_queue_adapter :inline
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  before do
    sign_in user if user
  end

  describe "new" do
    it_behaves_like "an access controlled new request"
  end

  context "when they have permission" do
    let(:user) { FactoryBot.create(:admin) }
    render_views
    it "has a form for creating scanned resources" do
      collection = FactoryBot.create_for_repository(:collection)
      parent = FactoryBot.create_for_repository(:simple_resource)

      get :new, params: { parent_id: parent.id.to_s }
      expect(response.body).to have_field "Title"
      expect(response.body).to have_field "Rights Statement"
      expect(response.body).to have_field "Rights Note"
      expect(response.body).to have_field "Local identifier"
      expect(response.body).to have_field "Portion Note"
      expect(response.body).to have_field "Navigation Date", class: "timepicker"
      expect(response.body).to have_selector "#simple_resource_append_id[value='#{parent.id}']", visible: false
      expect(response.body).to have_select "Collections", name: "simple_resource[member_of_collection_ids][]", options: [collection.title.first]
      expect(response.body).to have_select "Rights Statement", name: "simple_resource[rights_statement]", options: [""] + ControlledVocabulary.for(:rights_statement).all.map(&:label)
      expect(response.body).to have_select "PDF Type", name: "simple_resource[pdf_type]", options: ["Color PDF", "Grayscale PDF", "Bitonal PDF", "No PDF"]
      expect(response.body).to have_checked_field "Open"
      expect(response.body).to have_button "Save"
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
      post :create, params: { simple_resource: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      resource = find_resource(id)
      expect(resource.title).to contain_exactly "Title 1", "Title 2"
      expect(resource.depositor).to eq [user.uid]
    end
    it "renders the form if it doesn't create a scanned resource" do
      post :create, params: { simple_resource: invalid_params }
      expect(response).to render_template "valhalla/base/new"
    end
  end

  context "when joining a collection" do
    let(:user) { FactoryBot.create(:admin) }
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
      post :create, params: { simple_resource: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      expect(find_resource(id).member_of_collection_ids).to contain_exactly collection.id
    end
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :simple_resource }
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a book" do
      simple_resource = FactoryBot.create_for_repository(:simple_resource)
      delete :destroy, params: { id: simple_resource.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: simple_resource.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :simple_resource }
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
        simple_resource = FactoryBot.create_for_repository(:simple_resource)
        get :edit, params: { id: simple_resource.id.to_s }

        expect(response.body).to have_field "Title", with: simple_resource.title.first
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html" do
      context "access control" do
        let(:factory) { :simple_resource }
        let(:extra_params) { { simple_resource: { title: ["Two"] } } }
        it_behaves_like "an access controlled update request"
      end
      context "when a scanned resource doesn't exist" do
        it "raises an error" do
          expect { patch :update, params: { id: "test" } }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        end
      end
      context "when it does exist" do
        it "saves it and redirects" do
          simple_resource = FactoryBot.create_for_repository(:simple_resource)
          patch :update, params: { id: simple_resource.id.to_s, simple_resource: { title: ["Two"] } }

          expect(response).to be_redirect
          expect(response.location).to eq "http://test.host/catalog/#{simple_resource.id}"
          id = response.location.gsub("http://test.host/catalog/", "")
          reloaded = find_resource(id)

          expect(reloaded.title).to eq ["Two"]
        end
        it "renders the form if it fails validations" do
          simple_resource = FactoryBot.create_for_repository(:simple_resource)
          patch :update, params: { id: simple_resource.id.to_s, simple_resource: { title: [""] } }

          expect(response).to render_template "valhalla/base/edit"
        end
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        simple_resource = FactoryBot.create_for_repository(:simple_resource)
        patch :update, params: { id: simple_resource.id.to_s, simple_resource: { title: ["Two"] } }
        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/#{simple_resource.id}"
        id = response.location.gsub("http://test.host/catalog/", "")
        find_resource(id)
      end
    end

    context "json" do
      context "when not an admin" do
        let(:user) { FactoryBot.create(:user) }
        it "returns 403" do
          resource = FactoryBot.create_for_repository(:simple_resource)
          params = { id: resource.id.to_s, simple_resource: { member_ids: ["not_an_id"] }, format: :json }
          patch :update, params: params
          expect(response.status).to eq(403)
        end
      end

      context "when a scanned resource doesn't exist" do
        it "returns 404" do
          patch :update, params: { id: "not_an_id", format: :json }
          expect(response.status).to eq(404)
        end
      end
      it "renders the form if it fails validations" do
        simple_resource = FactoryBot.create_for_repository(:simple_resource)
        patch :update, params: { id: simple_resource.id.to_s, simple_resource: { title: [""] } }
        expect(response).to render_template "valhalla/base/edit"
      end

      context "when the scanned resource does exist" do
        context "invalid data submitted" do
          it "returns 400" do
            simple_resource = FactoryBot.create_for_repository(:simple_resource)
            params = { id: simple_resource.id.to_s, simple_resource: { title: [""] }, format: :json }
            patch :update, params: params
            expect(response.status).to eq(400)
          end
        end
        context "valid data submitted" do
          it "updates and returns 200" do
            file_set1 = FactoryBot.create_for_repository(:file_set)
            file_set2 = FactoryBot.create_for_repository(:file_set)
            simple_resource = FactoryBot.create_for_repository(:simple_resource, member_ids: [file_set1.id, file_set2.id])

            params = { id: simple_resource.id.to_s, simple_resource: { member_ids: [file_set2.id, file_set1.id] }, format: :json }
            patch :update, params: params
            expect(response.status).to eq(200)
            reloaded = find_resource(simple_resource.id)
            expect(reloaded.member_ids.first.to_s).to eq file_set2.id.to_s
          end
        end
      end
    end

    describe "json update" do
      let(:user) { FactoryBot.create(:admin) }

      context "when not an admin" do
        let(:user) { FactoryBot.create(:user) }
        it "returns 404" do
          resource = FactoryBot.create_for_repository(:simple_resource)
          params = { id: resource.id.to_s, simple_resource: { member_ids: ["not_an_id"] }, format: :json }
          patch :update, params: params
          expect(response.status).to eq(403)
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
          simple_resource = FactoryBot.create_for_repository(:simple_resource)
          params = { id: simple_resource.id.to_s, simple_resource: { title: [""] }, format: :json }
          patch :update, params: params
          expect(response.status).to eq(400)
        end
        it "updates and returns 200 for valid data" do
          file_set1 = FactoryBot.create_for_repository(:file_set)
          file_set2 = FactoryBot.create_for_repository(:file_set)
          simple_resource = FactoryBot.create_for_repository(:simple_resource, member_ids: [file_set1.id, file_set2.id])

          params = { id: simple_resource.id.to_s, simple_resource: { member_ids: [file_set2.id, file_set1.id] }, format: :json }
          patch :update, params: params
          expect(response.status).to eq(200)
          reloaded = find_resource(simple_resource.id)
          expect(reloaded.member_ids.first.to_s).to eq file_set2.id.to_s
        end
      end
    end
  end

  describe "GET /concern/simple_resources/:id/manifest" do
    let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
    it "returns a IIIF manifest for a resource with a file" do
      simple_resource = FactoryBot.create_for_repository(:simple_resource, files: [file])

      get :manifest, params: { id: simple_resource.id.to_s, format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:sequences].length).to eq 1
      expect(manifest_response[:viewingHint]).to eq "individuals"
    end
    context "when given a local identifier" do
      it "returns it still" do
        simple_resource = FactoryBot.create_for_repository(:simple_resource, local_identifier: "pk643fd004", files: [file])

        get :manifest, params: { id: simple_resource.local_identifier.first, format: :json }

        expect(response).to redirect_to manifest_simple_resource_path(id: simple_resource.id.to_s)
      end
    end
  end

  describe "GET /concern/simple_resources/:id/pdf" do
    let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
    let(:simple_resource) { FactoryBot.create_for_repository(:simple_resource, files: [file]) }
    let(:file_set) { simple_resource.member_ids.first }
    before do
      stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/gray.jpg")
        .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
    end
    it "generates a PDF, attaches it to the simple resource, and redirects to download for it" do
      get :pdf, params: { id: simple_resource.id.to_s }
      reloaded = adapter.query_service.find_by(id: simple_resource.id)

      expect(reloaded.file_metadata).not_to be_blank
      expect(reloaded.pdf_file).not_to be_blank
      expect(response).to redirect_to Valhalla::Engine.routes.url_helpers.download_path(resource_id: simple_resource.id.to_s, id: reloaded.pdf_file.id.to_s)
    end
  end

  # Helper method just for the test suite
  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
