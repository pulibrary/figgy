# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CatalogController do
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  describe "#index" do
    render_views
    it "finds all public documents" do
      persister.save(resource: FactoryGirl.build(:scanned_resource))

      get :index, params: { q: "" }

      expect(assigns(:document_list).length).to eq 1
    end
  end

  describe "FileSet behavior" do
    before do
      sign_in FactoryGirl.create(:admin)
    end
    it "doesn't display indexed FileSets" do
      persister.save(resource: FactoryGirl.build(:file_set))

      get :index, params: { q: "" }

      expect(assigns(:document_list).length).to eq 0
    end
  end

  describe "EphemeraFolder behavior" do
    before do
      sign_in FactoryGirl.create(:admin)
    end
    it "displays indexed EphemeraFolders" do
      folder = persister.save(resource: FactoryGirl.build(:ephemera_folder))
      persister.save(resource: FactoryGirl.build(:ephemera_box, member_ids: folder.id))
      persister.save(resource: folder)

      get :index, params: { q: "" }

      expect(assigns(:document_list).length).to eq 2
    end
  end

  describe "EphemeraBox behavior" do
    before do
      sign_in FactoryGirl.create(:admin)
    end
    it "displays indexed EphemeraBoxes" do
      persister.save(resource: FactoryGirl.build(:ephemera_box))

      get :index, params: { q: "" }

      expect(assigns(:document_list).length).to eq 1
    end
  end

  describe "FileMetadata behavior" do
    before do
      sign_in FactoryGirl.create(:admin)
    end
    it "doesn't display indexed FileMetadata nodes" do
      persister.save(resource: FileMetadata.new)

      get :index, params: { q: "" }

      expect(assigns(:document_list).length).to eq 0
    end
  end

  describe "incomplete record behavior" do
    context "as a user" do
      before do
        sign_in FactoryGirl.create(:user)
      end
      it "doesn't display incomplete items" do
        persister.save(resource: FactoryGirl.build(:pending_scanned_resource))

        get :index, params: { q: "" }

        expect(assigns(:document_list).length).to eq 0
      end
    end
    context "as an admin" do
      before do
        sign_in FactoryGirl.create(:admin)
      end
      it "displays incomplete items" do
        persister.save(resource: FactoryGirl.build(:pending_scanned_resource))

        get :index, params: { q: "" }

        expect(assigns(:document_list).length).to eq 1
      end
    end
  end

  describe "child resource behavior" do
    before do
      sign_in FactoryGirl.create(:admin)
    end
    it "doesn't display children of parented resources" do
      child = persister.save(resource: FactoryGirl.build(:scanned_resource))
      parent = persister.save(resource: FactoryGirl.build(:scanned_resource, member_ids: child.id))
      # Re-save to get member_of to index, not necessary if going through
      #   PlumChangeSetPersister.
      persister.save(resource: child)

      get :index, params: { q: "" }

      expect(assigns(:document_list).length).to eq 1
      expect(assigns(:document_list).first.resource.id).to eq parent.id
    end
  end

  describe "Collection behavior" do
    before do
      sign_in FactoryGirl.create(:admin)
    end

    it "displays indexed collections" do
      persister.save(resource: FactoryGirl.build(:collection))

      get :index, params: { q: "" }

      expect(assigns(:document_list).length).to eq 1
    end
    context "when a resource has a collection" do
      render_views
      it "facets on it" do
        collection = persister.save(resource: FactoryGirl.build(:collection))
        persister.save(resource: FactoryGirl.build(:scanned_resource, member_of_collection_ids: [collection.id]))

        get :index, params: { q: "" }

        expect(response.body).to have_selector ".facet-field-heading", text: "Collections"
        expect(response.body).to have_selector ".facet_select", text: collection.title.first
      end
    end
  end

  describe "nested catalog paths" do
    it "loads the parent document when given an ID" do
      child = persister.save(resource: FactoryGirl.build(:file_set))
      parent = persister.save(resource: FactoryGirl.build(:scanned_resource, member_ids: child.id))

      get :show, params: { parent_id: parent.id, id: child.id }

      expect(assigns(:parent_document)).not_to be_nil
    end
  end

  describe "#show" do
    context "when rendered for an admin" do
      before do
        sign_in FactoryGirl.create(:admin)
      end
      render_views
      it "renders administration buttons" do
        resource = persister.save(resource: FactoryGirl.build(:scanned_resource, workflow_note: WorkflowNote.new(author: "Shakespeare", note: "Test Comment")))

        get :show, params: { id: "id-#{resource.id}" }

        expect(response.body).to have_link "Edit This Scanned Resource", href: edit_scanned_resource_path(resource)
        expect(response.body).to have_link "Delete This Scanned Resource", href: scanned_resource_path(resource)
        expect(response.body).to have_link "File Manager", href: file_manager_scanned_resource_path(resource)
        expect(response.body).to have_link "Edit Structure", href: structure_scanned_resource_path(resource)
        expect(response.body).to have_button "Attach Child"
        expect(response.body).to have_link "Attach Scanned Resource", href: parent_new_scanned_resource_path(resource)
        expect(response.body).to have_content "Review and Approval"
        expect(response.body).to have_content "Shakespeare"
        expect(response.body).to have_content "Test Comment"
      end

      it "renders RDF views" do
        stub_bibdata(bib_id: "123456")
        stub_bibdata_context
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
        collection = FactoryGirl.create_for_repository(:collection)
        resource = FactoryGirl.create_for_repository(
          :scanned_resource,
          source_metadata_identifier: "123456",
          import_metadata: true,
          portion_note: "Test",
          nav_date: "Test",
          member_of_collection_ids: collection.id
        )

        get :show, params: { id: "id-#{resource.id}", format: :jsonld }

        expect(response).to be_success
        json_body = MultiJson.load(response.body, symbolize_keys: true)
        expect(json_body[:title][:@value]).to eq "Earth rites : fertility rites in pre-industrial Britain"
        expect(json_body[:identifier]).not_to be_blank
        expect(json_body[:scopeNote]).not_to be_blank
        expect(json_body[:navDate]).not_to be_blank
        expect(json_body[:edm_rights][:@id]).to eq "http://rightsstatements.org/vocab/NKC/1.0/"
        expect(json_body[:edm_rights][:@type]).to eq "dcterms:RightsStatement"
        expect(json_body[:edm_rights][:pref_label]).to eq "No Known Copyright"
        expect(json_body[:memberOf][0][:@id]).to eq "http://www.example.com/catalog/id-#{collection.id}"
        expect(json_body[:memberOf][0][:@type]).to eq "pcdm:Collection"
        expect(json_body[:memberOf][0][:title]).to eq collection.title

        get :show, params: { id: "id-#{resource.id}", format: :nt }
        expect(response).to be_success

        get :show, params: { id: "id-#{resource.id}", format: :ttl }
        expect(response).to be_success

        empty_resource = persister.save(resource: FactoryGirl.build(:scanned_resource))
        get :show, params: { id: "id-#{empty_resource.id}", format: :jsonld }
        expect(response).to be_success
        json_body = MultiJson.load(response.body, symbolize_keys: true)
        expect(json_body[:title]).not_to be_blank

        collection = persister.save(resource: FactoryGirl.build(:collection))
        get :show, params: { id: "id-#{collection.id}", format: :jsonld }
        expect(response).to be_success
      end

      it "renders for a FileSet" do
        resource = persister.save(resource: FactoryGirl.build(:file_set))

        get :show, params: { id: "id-#{resource.id}" }

        expect(response.body).to have_link "Edit This File Set", href: edit_file_set_path(resource)
        expect(response.body).to have_link "Delete This File Set", href: file_set_path(resource)
        expect(response.body).not_to have_link "File Manager"
      end

      it "renders for a Collection" do
        resource = persister.save(resource: FactoryGirl.build(:collection))

        get :show, params: { id: "id-#{resource.id}" }

        expect(response.body).to have_link "Edit This Collection", href: edit_collection_path(resource)
        expect(response.body).to have_link "Delete This Collection", href: collection_path(resource)
        expect(response.body).not_to have_link "File Manager"
      end

      it "renders for an Ephemera Folder" do
        resource = persister.save(resource: FactoryGirl.build(:ephemera_folder))

        get :show, params: { id: "id-#{resource.id}" }

        expect(response.body).to have_content "Review and Approval"
      end
      it "renders for an Ephemera Project" do
        resource = persister.save(resource: FactoryGirl.build(:ephemera_project))

        get :show, params: { id: "id-#{resource.id}" }

        expect(response.body).to have_selector "h1", text: resource.title.first
      end
      it "renders for an Ephemera Box" do
        resource = persister.save(resource: FactoryGirl.build(:ephemera_box))

        get :show, params: { id: "id-#{resource.id}" }

        expect(response.body).to have_content "Review and Approval"
      end
    end
    context "when rendered for a user" do
      render_views
      it "doesn't render the workflow panel" do
        resource = persister.save(resource: FactoryGirl.build(:complete_open_scanned_resource))

        get :show, params: { id: "id-#{resource.id}" }

        expect(response.body).not_to have_content "Review and Approval"
      end
    end
  end

  describe "#has_search_parameters?" do
    context "when only a q is passed" do
      it "returns true" do
        get :index, params: { q: "" }

        expect(controller).to have_search_parameters
      end
    end

    context "when not logged in" do
      it "does not display resources without the `public` read_groups" do
        FactoryGirl.create_for_repository(:complete_private_scanned_resource)

        get :index, params: { q: "" }

        expect(assigns(:document_list)).to be_empty
      end
    end

    context "when logged in as an admin" do
      it "displays all resources" do
        user = FactoryGirl.create(:admin)
        persister.save(resource: FactoryGirl.build(:scanned_resource, read_groups: nil, edit_users: nil))

        sign_in user
        get :index, params: { q: "" }

        expect(assigns(:document_list)).not_to be_empty
      end
    end
    context "when logged in" do
      it "displays resources which the user can edit" do
        user = FactoryGirl.create(:user)
        persister.save(resource: FactoryGirl.build(:scanned_resource, read_groups: nil, edit_users: user.user_key))

        sign_in user
        get :index, params: { q: "" }

        expect(assigns(:document_list)).not_to be_empty
      end
      it "displays resources which are explicitly given permission to that user" do
        user = FactoryGirl.create(:user)
        persister.save(resource: FactoryGirl.build(:scanned_resource, read_groups: nil, read_users: user.user_key))

        sign_in user
        get :index, params: { q: "" }

        expect(assigns(:document_list)).not_to be_empty
      end
    end
  end

  describe "manifest lookup" do
    context "when the manifest is found" do
      let(:resource) { persister.save(resource: FactoryGirl.build(:scanned_resource, identifier: ['ark:/99999/12345'])) }

      before do
        resource
      end

      it "redirects to the manifest" do
        get :lookup_manifest, params: { prefix: 'ark:', naan: '99999', arkid: '12345' }
        expect(response).to redirect_to "http://test.host/concern/scanned_resources/#{resource.id}/manifest"
      end
      it "doesn't redirect when no_redirect is set" do
        get :lookup_manifest, params: { prefix: 'ark:', naan: '99999', arkid: '12345', no_redirect: 'true' }
        expect(response).to be_success
        expect(JSON.parse(response.body)["url"]).to eq "http://test.host/concern/scanned_resources/#{resource.id}/manifest"
      end
    end

    context "when the manifeset is not found" do
      it "sends a 404 error" do
        get :lookup_manifest, params: { prefix: 'ark:', naan: '99999', arkid: '99999' }
        expect(response.status).to be 404
      end
    end
  end
end
