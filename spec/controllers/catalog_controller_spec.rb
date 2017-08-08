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
        resource = persister.save(resource: FactoryGirl.build(:scanned_resource))

        get :show, params: { id: "id-#{resource.id}" }

        expect(response.body).to have_link "Edit This Scanned Resource", href: edit_scanned_resource_path(resource)
        expect(response.body).to have_link "Delete This Scanned Resource", href: scanned_resource_path(resource)
        expect(response.body).to have_link "File Manager", href: file_manager_scanned_resource_path(resource)
        expect(response.body).to have_link "Edit Structure", href: structure_scanned_resource_path(resource)
        expect(response.body).to have_button "Attach Child"
        expect(response.body).to have_link "Attach Scanned Resource", href: parent_new_scanned_resource_path(resource)
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
end
