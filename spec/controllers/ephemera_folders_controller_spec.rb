# frozen_string_literal: true
require "rails_helper"

RSpec.describe EphemeraFoldersController, type: :controller do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:valid_params) do
    {
      barcode: ["12345678901234"],
      folder_number: ["one"],
      title: ["test folder"],
      language: ["test language"],
      genre: ["test genre"],
      width: ["10"],
      height: ["20"],
      page_count: ["30"],
      rights_statement: RightsStatements.no_known_copyright.to_s,
      visibility: "restricted",
      subject: ["stuff"]
    }
  end
  let(:invalid_params) do
    {
      barcode: nil,
      folder_number: nil,
      title: nil,
      language: nil,
      genre: nil,
      width: nil,
      height: nil,
      page_count: nil,
      rights_statement: "Test Statement",
      visibility: "restricted",
      subject: nil
    }
  end
  before do
    sign_in user if user
  end

  describe "new" do
    it_behaves_like "an access controlled new request"

    context "when they have permission to edit the parent" do
      let(:user) { FactoryBot.create(:user) }
      render_views
      it "renders a form for editing the folder" do
        box = FactoryBot.create_for_repository(:ephemera_box)
        FactoryBot.create_for_repository(:ephemera_project, member_ids: box.id, contributor_uids: user.uid)

        get :new, params: { parent_id: box.id.to_s }

        expect(response.body).to have_field "Folder number"
        expect(response.body).to have_field "Content warning"
        expect(response.body).to have_content "Displays a Harmful Content Warning in the viewer with the given text if filled."
      end
    end

    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has a form for creating ephemera folders" do
        get :new
        expect(response.body).to have_field "Folder number"
        expect(response.body).to have_button "Save"
      end
      it "can use a passed template ID to pre-generate fields" do
        template = FactoryBot.create_for_repository(:template, nested_properties: [EphemeraFolder.new(language: "Test")])
        FactoryBot.create_for_repository(:ephemera_folder)

        get :new, params: { template_id: template.id.to_s }

        expect(response.body).to have_field "Language", with: "Test"
      end
      it "can be passed a previously created record to pre-generate fields" do
        record = FactoryBot.create_for_repository(:ephemera_folder, language: "Test")

        get :new, params: { create_another: record.id.to_s }

        expect(response.body).to have_field "Language", with: "Test"
      end
    end
    context "when created within a box" do
      it "doesn't set @available_boxes and @selected_box" do
        box = FactoryBot.create_for_repository(:ephemera_box)
        FactoryBot.create_for_repository(:ephemera_project, member_ids: box.id)

        get :new, params: { parent_id: box.id.to_s }

        expect(assigns(:available_boxes)).to be_nil
        expect(assigns(:selected_box)).to be_nil
      end
      it "sets @parent_box_number" do
        box = FactoryBot.create_for_repository(:ephemera_box)
        FactoryBot.create_for_repository(:ephemera_project, member_ids: box.id)

        get :new, params: { parent_id: box.id.to_s }
        expect(assigns(:parent_box_number)).to eq "1"
      end
    end
    context "when created within a folder" do
      it "sets @available_boxes and @selected_box" do
        box = FactoryBot.create_for_repository(:ephemera_box)
        project = FactoryBot.create_for_repository(:ephemera_project, member_ids: box.id)

        get :new, params: { parent_id: project.id.to_s }

        expect(assigns(:available_boxes)).to be_nil
        expect(assigns(:selected_box)).to be_nil
      end
      it "doesn't set @parent_box_number" do
        box = FactoryBot.create_for_repository(:ephemera_box)
        project = FactoryBot.create_for_repository(:ephemera_project, member_ids: box.id)

        get :new, params: { parent_id: project.id.to_s }
        expect(assigns(:parent_box_number)).to be_nil
      end
    end
  end

  describe "manifest" do
    context "when not logged in but an auth token is given" do
      it "renders the full manifest" do
        resource = FactoryBot.create_for_repository(:campus_only_ephemera_folder)
        authorization_token = AuthToken.create!(group: ["admin"], label: "admin_token")
        get :manifest, params: { id: resource.id, format: :json, auth_token: authorization_token.token }

        expect(response).to be_successful
        expect(response.body).not_to eq "{}"
      end
    end
  end

  describe "GET /concern/ephemera_folders/:id/manifest" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    context "when signed in as an admin" do
      let(:user) { FactoryBot.create(:admin) }
      it "returns a IIIF manifest for a resource with a file" do
        sign_in user
        resource = FactoryBot.create_for_repository(:ephemera_folder, files: [file])

        get :manifest, params: { id: resource.id.to_s, format: :json }
        manifest_response = MultiJson.load(response.body, symbolize_keys: true)

        expect(response.headers["Content-Type"]).to include "application/json"
        expect(manifest_response[:sequences].length).to eq 1
        expect(manifest_response[:viewingHint]).to eq "individuals"
      end
      context "when given a video", run_real_derivatives: true, run_real_characterization: true do
        let(:file) { fixture_file_upload("files/city.mp4", "video/mp4") }
        it "renders a v3 manifest" do
          sign_in user
          resource = FactoryBot.create_for_repository(:ephemera_folder, files: [file])

          get :manifest, params: { id: resource.id.to_s, format: :json }
          manifest_response = MultiJson.load(response.body)

          expect(response.headers["Content-Type"]).to include "application/json"
          expect(manifest_response["@context"]).to include("http://iiif.io/api/presentation/3/context.json")
          expect(manifest_response["items"].first["items"][0]["items"][0]["body"]["type"]).to eq "Video"
        end
      end
    end
    context "when not signed in as an admin" do
      it "does not display needs_qa items" do
        resource = FactoryBot.create_for_repository(:ephemera_folder, files: [file])

        get :manifest, params: { id: resource.id.to_s, format: :json }

        expect(response).to be_forbidden
      end
      it "displays complete items" do
        resource = FactoryBot.create_for_repository(:complete_ephemera_folder, files: [file])

        expect { get :manifest, params: { id: resource.id.to_s, format: :json } }
          .not_to raise_error
      end
      it "displays needs_qa items which have an all_in_production box" do
        resource = FactoryBot.create_for_repository(:ephemera_folder)
        FactoryBot.create_for_repository(:ephemera_box, member_ids: resource.id, state: "all_in_production")

        expect { get :manifest, params: { id: resource.id.to_s, format: :json } }.not_to raise_error
      end
    end
  end

  describe "create" do
    let(:user) { FactoryBot.create(:admin) }

    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end

    context "when they have permission to update the parent" do
      let(:user) { FactoryBot.create(:user) }
      it "can create an ephemera folder" do
        box = FactoryBot.create_for_repository(:ephemera_box)
        FactoryBot.create_for_repository(:ephemera_project, member_ids: box.id, contributor_uids: user.uid)

        post :create, params: { ephemera_folder: valid_params.merge(append_id: box.id) }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
      end
    end

    it "can create an ephemera folder" do
      post :create, params: { ephemera_folder: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      resource = find_resource(id)
      expect(resource.folder_number).to contain_exactly "one"
      expect(resource.depositor).to eq [user.uid]
    end
    it "can save and create another" do
      box = FactoryBot.create_for_repository(:ephemera_box)
      post :create, params: { commit: "Save and Duplicate Metadata", ephemera_folder: valid_params.merge(append_id: box.id) }
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/ephemera_boxes/#{box.id}/ephemera_folders/new?create_another"
    end
    it "can save a draft" do
      post :create, params: { commit: "Save Draft", ephemera_folder: valid_params.merge(subject: []) }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/catalog/"
      id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
      resource = find_resource(id)
      expect(resource.folder_number).to contain_exactly "one"
      expect(resource.depositor).to eq [user.uid]
      expect(resource.subject).to be_blank
    end
    it "indexes the folder with the project it's a part of" do
      box = FactoryBot.create_for_repository(:ephemera_box)
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: box.id)
      post :create, params: { ephemera_folder: valid_params.merge(append_id: box.id) }

      id = query_service.find_all_of_model(model: EphemeraFolder).to_a.first.id
      solr_record = Blacklight.default_index.connection.get("select", params: { q: "id:#{id}", rows: 1 })["response"]["docs"].first
      expect(solr_record["ephemera_project_ssim"]).to eq project.title
    end
    context "when something bad goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post :create, params: { ephemera_folder: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post :create, params: { ephemera_folder: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    it "renders the form if it doesn't create a ephemera folder" do
      post :create, params: { ephemera_folder: invalid_params }
      expect(response).to render_template "base/new"
    end
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_folder }
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a folder in a box" do
      ephemera_folder = FactoryBot.create_for_repository(:ephemera_folder)
      ephemera_box = FactoryBot.create_for_repository(:ephemera_box, member_ids: ephemera_folder.id)
      delete :destroy, params: { id: ephemera_folder.id.to_s }

      expect(response).to redirect_to solr_document_path(id: ephemera_box.id)
      expect { query_service.find_by(id: ephemera_folder.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
    it "can delete a boxless folder" do
      ephemera_folder = FactoryBot.create_for_repository(:ephemera_folder)
      ephemera_project = FactoryBot.create_for_repository(:ephemera_project, member_ids: ephemera_folder.id)
      delete :destroy, params: { id: ephemera_folder.id.to_s }

      expect(response).to be_redirect
      expect(response).to redirect_to solr_document_path(id: ephemera_project.id)
      expect { query_service.find_by(id: ephemera_folder.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :ephemera_folder }
      it_behaves_like "an access controlled edit request"
    end
    context "when a ephemera folder doesn't exist" do
      it "raises an error" do
        get :edit, params: { id: "test" }
        expect(response).to have_http_status(404)
      end
    end
    context "when it does exist" do
      render_views
      it "renders a form" do
        ephemera_folder = FactoryBot.create_for_repository(:ephemera_folder)
        get :edit, params: { id: ephemera_folder.id.to_s }

        expect(response.body).to have_field "Folder number", with: ephemera_folder.folder_number.first
        expect(response.body).to have_button "Save"
      end
    end
    context "when it has filesets" do
      render_views
      it "renders the viewer" do
        file_set = FactoryBot.create_for_repository(:file_set)
        ephemera_folder = FactoryBot.create_for_repository(:ephemera_folder, member_ids: file_set.id)
        get :edit, params: { id: ephemera_folder.id.to_s }

        expect(response.body).to have_selector ".uv-container"
      end
    end

    context "when inside a box" do
      it "sets @available_boxes and @selected_box" do
        ephemera_folder = FactoryBot.create_for_repository(:ephemera_folder)
        box = FactoryBot.create_for_repository(:ephemera_box, member_ids: ephemera_folder.id)
        FactoryBot.create_for_repository(:ephemera_project, member_ids: box.id)

        get :edit, params: { id: ephemera_folder.id.to_s }

        expect(assigns(:available_boxes).map(&:title)).to include "Box 1"
        expect(assigns(:selected_box)).to eq box.id.to_s
      end
    end
    context "when boxless" do
      it "sets @available_boxes and @selected_box" do
        box = FactoryBot.create_for_repository(:ephemera_box)
        ephemera_folder = FactoryBot.create_for_repository(:ephemera_folder)
        FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, ephemera_folder.id])

        get :edit, params: { id: ephemera_folder.id.to_s }

        expect(assigns(:available_boxes).map(&:title)).to include "Box 1"
        expect(assigns(:selected_box)).to eq ""
      end
    end

    context "with fields" do
      let(:user) { FactoryBot.create(:admin) }
      let(:vocab) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "test vocabulary") }
      let(:term) { FactoryBot.create_for_repository(:ephemera_term, label: "test term", member_of_vocabulary_id: vocab.id) }
      let(:field) { FactoryBot.create_for_repository(:ephemera_field, field_name: "1", member_of_vocabulary_id: vocab.id) }
      let(:box) { FactoryBot.create_for_repository(:ephemera_box) }
      let(:project) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, field.id]) }

      render_views
      it "retrieves project field terms for the folder" do
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        ephemera_folder = FactoryBot.create_for_repository(:ephemera_folder)
        box.member_ids = [ephemera_folder.id]
        adapter.persister.save(resource: box)

        term.member_of_vocabulary_id = vocab.id
        adapter.persister.save(resource: term)

        field.member_of_vocabulary_id = vocab.id
        adapter.persister.save(resource: field)

        project.member_ids = [box.id, field.id]
        adapter.persister.save(resource: project)

        get :edit, params: { id: ephemera_folder.id.to_s, parent_id: box.id }

        expect(assigns(:language)).not_to be_empty
        expect(assigns(:language).first).to be_an EphemeraTermDecorator
        expect(assigns(:language).first.label).to eq "test term"
      end
    end

    context "with a subject field" do
      let(:user) { FactoryBot.create(:admin) }
      let(:vocab) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "test vocabulary") }
      let(:term) { FactoryBot.create_for_repository(:ephemera_term, label: "test term", member_of_vocabulary_id: child_vocab.id) }
      let(:field) { FactoryBot.create_for_repository(:ephemera_field, field_name: "5", member_of_vocabulary_id: vocab.id, rarely_used_term_ids: [term.id]) }
      let(:box) { FactoryBot.create_for_repository(:ephemera_box) }
      let(:project) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, field.id]) }
      let(:child_vocab) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "test child vocabulary") }
      let(:ephemera_folder) { FactoryBot.create_for_repository(:ephemera_folder) }

      render_views
      before do
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        box.member_ids = [ephemera_folder.id]
        adapter.persister.save(resource: box)

        child_vocab.member_of_vocabulary_id = vocab.id
        adapter.persister.save(resource: child_vocab)

        field.member_of_vocabulary_id = vocab.id
        adapter.persister.save(resource: field)

        project.member_ids = [box.id, field.id]
        adapter.persister.save(resource: project)
      end

      it "retrieves project field terms for the folder" do
        get :edit, params: { id: ephemera_folder.id.to_s, parent_id: box.id }

        expect(assigns(:subject)).not_to be_empty
        expect(assigns(:subject).first.label).to eq "Favorites"
        expect(assigns(:subject).second.label).to eq "test child vocabulary"
        expect(assigns(:subject).last.label).to eq "Rarely Used"
        # Ensure rarely used terms fall out of their categories.
        expect(assigns(:subject).second.terms.length).to eq 0
        expect(assigns(:subject).last.terms.length).to eq 1
      end
    end
  end

  describe "update" do
    let(:user) { FactoryBot.create(:admin) }
    it_behaves_like "a workflow controller", :ephemera_folder
    context "access control" do
      let(:factory) { :ephemera_folder }
      let(:extra_params) { { ephemera_folder: { title: ["Two"] } } }
      it_behaves_like "an access controlled update request"
    end
    context "when a ephemera folder doesn't exist" do
      it "raises an error" do
        patch :update, params: { id: "test" }
        expect(response).to have_http_status(404)
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        ephemera_folder = FactoryBot.create_for_repository(:ephemera_folder)
        patch :update, params: { id: ephemera_folder.id.to_s, ephemera_folder: { subject: ["", "bla"], folder_number: ["Two"] } }

        expect(response).to be_redirect
        expect(response.location).to eq "http://test.host/catalog/#{ephemera_folder.id}"
        id = response.location.gsub("http://test.host/catalog/", "")
        reloaded = find_resource(id)

        expect(reloaded.folder_number).to eq ["Two"]
      end
      it "can save and create another" do
        folder = FactoryBot.create_for_repository(:ephemera_folder)
        box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id])
        patch :update, params: { commit: "Save and Duplicate Metadata", id: folder.id.to_s, ephemera_folder: { folder_number: ["Two"] } }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/concern/ephemera_boxes/#{box.id}/ephemera_folders/new?create_another"

        reloaded = find_resource(folder.id)
        expect(reloaded.folder_number).to eq ["Two"]
      end
      it "renders the form if it fails validations" do
        ephemera_folder = FactoryBot.create_for_repository(:ephemera_folder)
        patch :update, params: { id: ephemera_folder.id.to_s, ephemera_folder: invalid_params }

        expect(response).to render_template "ephemera_folders/edit"
      end

      it "can change from having a project as a parent to having a box as a parent" do
        folder = FactoryBot.create_for_repository(:ephemera_folder)
        box = FactoryBot.create_for_repository(:ephemera_box)
        FactoryBot.create_for_repository(:ephemera_project, member_ids: [folder.id])
        patch :update, params: { id: folder.id.to_s, ephemera_folder: { append_id: box.id } }

        parents = Wayfinder.for(find_resource(folder.id)).parents
        expect(parents.count).to eq 1
        expect(parents.first.id).to eq box.id
      end
    end
  end

  describe "#pdf" do
    let(:factory) { :ephemera_folder }

    it_behaves_like "a Pdfable"
  end

  context "when an admin" do
    let(:user) { FactoryBot.create(:admin) }
    describe "GET /ephemera_folders/:id/file_manager" do
      it "sets the record and children variables" do
        child = FactoryBot.create_for_repository(:file_set)
        parent = FactoryBot.create_for_repository(:ephemera_folder, member_ids: child.id)

        get :file_manager, params: { id: parent.id }

        expect(assigns(:change_set).id).to eq parent.id
        expect(assigns(:children).map(&:id)).to eq [child.id]
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
