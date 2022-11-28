# frozen_string_literal: true
require "rails_helper"

RSpec.shared_examples "a ResourcesController" do |*flags|
  include ActionDispatch::Routing::PolymorphicRoutes
  include Rails.application.routes.url_helpers
  with_queue_adapter :inline
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:model_name) { ActiveModel::Naming.singular resource_klass }
  let(:param_key) { ActiveModel::Naming.param_key resource_klass }
  let(:factory) { param_key }

  before do
    raise "resource_klass must be set with `let(:resource_klass)`" unless
      defined? resource_klass
    sign_in user if user
  end

  describe "new" do
    it_behaves_like "an access controlled new request"

    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has a form for creating resources" do
        collection = FactoryBot.create_for_repository(:collection)
        parent = FactoryBot.create_for_repository(factory)

        get :new, params: { parent_id: parent.id.to_s }
        expect(response.body).to have_field "Title"
        expect(response.body).to have_field "Rights Statement"
        expect(response.body).to have_field "Rights Note"
        expect(response.body).to have_field "Local identifier"
        expect(response.body).to have_field "Portion Note"
        expect(response.body).to have_field "Navigation Date", class: "timepicker"
        expect(response.body).to have_selector "##{model_name}_append_id[value='#{parent.id}']", visible: false
        expect(response.body).not_to have_select "Collections", name: "#{model_name}[member_of_collection_ids][]", options: [collection.title.first]
        expect(response.body).to have_select "Rights Statement", name: "#{model_name}[rights_statement]", options: [""] + ControlledVocabulary.for(:rights_statement).all.map(&:label)
        expect(response.body).to have_select "PDF Type", name: "#{model_name}[pdf_type]", options: ["Color PDF", "Grayscale PDF", "Bitonal PDF", "No PDF"]
        languages = Tesseract.languages
        expect(response.body).to have_select "OCR Language", name: "#{model_name}[ocr_language]", options: languages.values + [""]
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
        rights_statement: RightsStatements.copyright_not_evaluated,
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
    it "can create a new resource" do
      post :create, params: { param_key => valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      resource = find_resource(id)
      expect(resource.title).to contain_exactly "Title 1", "Title 2"
      expect(resource.depositor).to eq [user.uid]
    end

    context "when joining a collection" do
      let(:user) { FactoryBot.create(:admin) }
      let(:valid_params) do
        {
          title: ["Title 1", "Title 2"],
          rights_statement: RightsStatements.copyright_not_evaluated,
          visibility: "restricted",
          member_of_collection_ids: [collection.id.to_s]
        }
      end
      let(:collection) { FactoryBot.create_for_repository(:collection) }
      it "works" do
        post :create, params: { param_key => valid_params }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
        expect(find_resource(id).member_of_collection_ids).to contain_exactly collection.id
      end
    end

    it "can create a nested resource" do
      parent = FactoryBot.create_for_repository(factory)
      post :create, params: { param_key => valid_params.merge(append_id: parent.id.to_s) }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/parent/#{parent.id}/"
      id = response.location.gsub("http://test.host/catalog/parent/#{parent.id}/", "")
      expect(find_resource(id).title).to contain_exactly "Title 1", "Title 2"
      expect(find_resource(parent.id).member_ids).to eq [Valkyrie::ID.new(id)]
      solr_record = Blacklight.default_index.connection.get("select", params: { qt: "document", q: "id:#{id}" })["response"]["docs"][0]
      expect(solr_record["member_of_ssim"]).to eq ["id-#{parent.id}"]
    end
    context "when something bad goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: { param_key => valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: { param_key => valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end

    it "renders the form if it doesn't create a new resource" do
      post :create, params: { param_key => invalid_params }
      expect(response).to render_template "base/new"
    end

    context "when an invalid source metadata ID is provided" do
      let(:invalid_metadata_params) do
        {
          source_metadata_identifier: "CD- 34517q"
        }
      end
      before do
        allow(Rails.logger).to receive(:error)
      end

      it "renders the form for a new resource, and both logs and flashes an error message" do
        post :create, params: { param_key => valid_params.merge(invalid_metadata_params) }

        expect(response).to render_template "base/new"
        expect(Rails.logger).to have_received(:error).with("Invalid source metadata ID: CD- 34517q")
        expect(flash[:error]).to eq "Invalid source metadata ID: CD- 34517q"
      end
    end
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a resource" do
      resource = FactoryBot.create_for_repository(factory)
      delete :destroy, params: { id: resource.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: resource.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
    it "returns a 404 when given a bad resource ID" do
      delete :destroy, params: { id: SecureRandom.uuid }
      expect(response).to have_http_status(404)
    end
  end

  describe "edit" do
    before do
      skip "no edit functionality" if flags.include?(:skip_edit)
    end
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      it_behaves_like "an access controlled edit request"
    end
    context "when a resource doesn't exist" do
      it "redirects" do
        get :edit, params: { id: "test" }
        expect(response).to have_http_status(404)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        resource = FactoryBot.create_for_repository(factory)
        get :edit, params: { id: resource.id.to_s }

        expect(response.body).to have_field "Title", with: resource.title.first
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html" do
      context "access control" do
        let(:extra_params) { { param_key => { title: ["Two"] } } }
        it_behaves_like "an access controlled update request"
      end
      context "when a resource doesn't exist" do
        it "raises an error" do
          patch :update, params: { id: "test" }
          expect(response).to have_http_status(404)
        end
      end
      context "when it does exist" do
        it "saves it and redirects" do
          resource = FactoryBot.create_for_repository(factory)
          patch :update, params: { id: resource.id.to_s, param_key => { title: ["Two"] } }

          expect(response).to be_redirect
          expect(response.location).to eq "http://test.host/catalog/#{resource.id}"
          id = response.location.gsub("http://test.host/catalog/", "")
          reloaded = find_resource(id)

          expect(reloaded.title).to eq ["Two"]
        end
        it "renders the form if it fails validations" do
          resource = FactoryBot.create_for_repository(factory)
          patch :update, params: { id: resource.id.to_s, param_key => { title: [""] } }

          expect(response).to render_template "base/edit"
        end
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        resource = FactoryBot.create_for_repository(factory)
        patch :update, params: { id: resource.id.to_s, param_key => { title: ["Two"] } }
        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/#{resource.id}"
        id = response.location.gsub("http://test.host/catalog/", "")
        find_resource(id)
      end
    end

    context "json" do
      context "when not an admin" do
        let(:user) { FactoryBot.create(:user) }
        it "returns 403" do
          resource = FactoryBot.create_for_repository(factory)
          params = { id: resource.id.to_s, param_key => { member_ids: ["not_an_id"] }, format: :json }
          patch :update, params: params
          expect(response.status).to eq(403)
        end
      end

      context "when a resource doesn't exist" do
        it "returns 404" do
          patch :update, params: { id: "not_an_id", format: :json }
          expect(response.status).to eq(404)
        end
      end
      it "renders the form if it fails validations" do
        resource = FactoryBot.create_for_repository(factory)
        patch :update, params: { id: resource.id.to_s, param_key => { title: [""] } }
        expect(response).to render_template "base/edit"
      end

      context "when the resource does exist" do
        context "invalid data submitted" do
          it "returns 400" do
            resource = FactoryBot.create_for_repository(factory)
            params = { id: resource.id.to_s, param_key => { title: [""] }, format: :json }
            patch :update, params: params
            expect(response.status).to eq(400)
          end
        end
        context "valid data submitted" do
          it "updates and returns 200" do
            file_set1 = FactoryBot.create_for_repository(:file_set)
            file_set2 = FactoryBot.create_for_repository(:file_set)
            resource = FactoryBot.create_for_repository(factory, member_ids: [file_set1.id, file_set2.id])

            params = { id: resource.id.to_s, param_key => { member_ids: [file_set2.id, file_set1.id] }, format: :json }
            patch :update, params: params
            expect(response.status).to eq(200)
            reloaded = find_resource(resource.id)
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
          resource = FactoryBot.create_for_repository(factory)
          params = { id: resource.id.to_s, param_key => { member_ids: ["not_an_id"] }, format: :json }
          patch :update, params: params
          expect(response.status).to eq(403)
        end
      end

      context "when a resource doesn't exist" do
        it "returns 404" do
          patch :update, params: { id: "not_an_id", format: :json }
          expect(response.status).to eq(404)
        end
      end

      context "when the resource does exist" do
        it "returns 400 for invalid data" do
          resource = FactoryBot.create_for_repository(factory)
          params = { id: resource.id.to_s, param_key => { title: [""] }, format: :json }
          patch :update, params: params
          expect(response.status).to eq(400)
        end
        it "updates and returns 200 for valid data" do
          file_set1 = FactoryBot.create_for_repository(:file_set)
          file_set2 = FactoryBot.create_for_repository(:file_set)
          resource = FactoryBot.create_for_repository(factory, member_ids: [file_set1.id, file_set2.id])

          params = { id: resource.id.to_s, param_key => { member_ids: [file_set2.id, file_set1.id] }, format: :json }
          patch :update, params: params
          expect(response.status).to eq(200)
          reloaded = find_resource(resource.id)
          expect(reloaded.member_ids.first.to_s).to eq file_set2.id.to_s
        end
      end
    end
  end

  context "when an admin" do
    let(:user) { FactoryBot.create(:admin) }
    describe "#file_manager" do
      it "sets the record and children variables" do
        child = FactoryBot.create_for_repository(:file_set)
        parent = FactoryBot.create_for_repository(factory, member_ids: child.id)

        get :file_manager, params: { id: parent.id }

        expect(assigns(:change_set).id).to eq parent.id
        expect(assigns(:children).map(&:id)).to eq [child.id]
      end
    end
  end

  describe "#manifest" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    before do
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "returns a IIIF manifest for a resource with a file" do
      resource = FactoryBot.create_for_repository(manifestable_factory, files: [file])

      get :manifest, params: { id: resource.id.to_s, format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:sequences].length).to eq 1
      expect(manifest_response[:viewingHint]).to eq "individuals"
    end
    context "when given a local identifier" do
      it "returns it still" do
        resource = FactoryBot.create_for_repository(factory, local_identifier: "pk643fd004", files: [file])

        get :manifest, params: { id: resource.local_identifier.first, format: :json }

        expect(response).to redirect_to polymorphic_path [:manifest, resource]
      end
    end
  end

  describe "#pdf" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:resource) { FactoryBot.create_for_repository(factory, files: [file]) }
    let(:file_set) { resource.member_ids.first }
    before do
      stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/gray.jpg")
        .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
    end
    it "generates a PDF, attaches it to the simple resource, and redirects to download for it" do
      get :pdf, params: { id: resource.id.to_s }
      reloaded = adapter.query_service.find_by(id: resource.id)

      expect(reloaded.file_metadata).not_to be_blank
      expect(reloaded.pdf_file).not_to be_blank
      expect(response).to redirect_to Rails.application.routes.url_helpers.download_path(resource_id: resource.id.to_s, id: reloaded.pdf_file.id.to_s)
    end
  end
end
