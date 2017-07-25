# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CatalogController do
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  describe "#index" do
    it "finds all public documents" do
      persister.save(resource: FactoryGirl.build(:scanned_resource))

      get :index, params: { q: "" }

      expect(assigns(:document_list).length).to eq 1
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
        persister.save(resource: FactoryGirl.build(:scanned_resource, read_groups: nil))

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
