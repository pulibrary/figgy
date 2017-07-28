# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Scanned Resources Management" do
  let(:user) { FactoryGirl.create(:admin) }
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
        expect { get "/concern/scanned_resources/new" }.to raise_error CanCan::AccessDenied
      end
    end
    it "has a form for creating scanned resources" do
      get "/concern/scanned_resources/new"
      expect(response.body).to have_field "Title"
      expect(response.body).to have_field "Source Metadata ID"
      expect(response.body).to have_field "scanned_resource[refresh_remote_metadata]"
      expect(response.body).to have_field "Rights Statement"
      expect(response.body).to have_field "Rights Note"
      expect(response.body).to have_field "Local identifier"
      expect(response.body).to have_field "Holding Location"
      expect(response.body).to have_field "PDF Type"
      expect(response.body).to have_field "Portion Note"
      expect(response.body).to have_field "Navigation Date"
      expect(response.body).to have_checked_field "Private"
      expect(response.body).to have_button "Save"
    end
  end

  describe "create" do
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
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        expect { post "/concern/scanned_resources", params: { scanned_resource: valid_params } }.to raise_error CanCan::AccessDenied
      end
    end
    it "can create a scanned resource" do
      post "/concern/scanned_resources", params: { scanned_resource: valid_params }

      expect(response).to be_redirect
      expect(response.location).to start_with "http://www.example.com/catalog/"
      id = response.location.gsub("http://www.example.com/catalog/", "").gsub("%2F", "/").gsub(/^id-/, "")
      expect(find_resource(id).title).to contain_exactly "Title 1", "Title 2"
    end
    context "when something bad goes wrong" do
      it "doesn't persist anything at all when it's solr erroring" do
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:index_solr).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_raise("Bad")

        expect do
          post "/concern/scanned_resources", params: { scanned_resource: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
      end

      it "doesn't persist anything at all when it's postgres erroring" do
        allow(Valkyrie::MetadataAdapter.find(:postgres)).to receive(:persister).and_return(
          Valkyrie::MetadataAdapter.find(:postgres).persister
        )
        allow(Valkyrie::MetadataAdapter.find(:postgres).persister).to receive(:save).and_raise("Bad")
        expect do
          post "/concern/scanned_resources", params: { scanned_resource: valid_params }
        end.to raise_error "Bad"
        expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all.to_a.length).to eq 0
        expect(Valkyrie::MetadataAdapter.find(:index_solr).query_service.find_all.to_a.length).to eq 0
      end
    end
    it "renders the form if it doesn't create a scanned resource" do
      post "/concern/scanned_resources", params: { scanned_resource: invalid_params }
      expect(response.body).to have_field "Title"
    end
  end

  describe "destroy" do
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        scanned_resource = FactoryGirl.create_for_repository(:scanned_resource)
        expect { delete scanned_resource_path(scanned_resource) }.to raise_error CanCan::AccessDenied
      end
    end
    it "can delete a book" do
      scanned_resource = FactoryGirl.create_for_repository(:scanned_resource)
      delete scanned_resource_path(scanned_resource)

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: scanned_resource.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "edit" do
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        scanned_resource = FactoryGirl.create_for_repository(:scanned_resource)

        expect { get edit_scanned_resource_path(scanned_resource) }.to raise_error CanCan::AccessDenied
      end
    end
    context "when a scanned resource doesn't exist" do
      it "raises an error" do
        expect { get edit_scanned_resource_path(id: "test") }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      let(:book) { Persister.save(resource: Book.new(title: ["Testing"])) }
      it "renders a form" do
        scanned_resource = FactoryGirl.create_for_repository(:scanned_resource)
        get edit_scanned_resource_path(scanned_resource)

        expect(response.body).to have_field "Title", with: scanned_resource.title.first
        expect(response.body).to have_button "Save"
      end
    end
  end

  describe "update" do
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        scanned_resource = FactoryGirl.create_for_repository(:scanned_resource)

        expect { patch scanned_resource_path(scanned_resource), params: { scanned_resource: { title: ["Two"] } } }.to raise_error CanCan::AccessDenied
      end
    end
    context "when a scanned resource doesn't exist" do
      it "raises an error" do
        expect { patch scanned_resource_path(id: "test") }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      it "saves it and redirects" do
        scanned_resource = FactoryGirl.create_for_repository(:scanned_resource)
        patch scanned_resource_path(scanned_resource), params: { scanned_resource: { title: ["Two"] } }

        expect(response).to be_redirect
        expect(response.location).to eq solr_document_url(id: "id-#{scanned_resource.id}")

        get response.location
        expect(response.body).to have_content "Two"
      end
      it "renders the form if it fails validations" do
        scanned_resource = FactoryGirl.create_for_repository(:scanned_resource)
        patch scanned_resource_path(scanned_resource), params: { scanned_resource: { title: [""] } }

        expect(response.body).to have_field "Title"
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
