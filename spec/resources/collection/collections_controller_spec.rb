# frozen_string_literal: true
require "rails_helper"

RSpec.describe CollectionsController, type: :controller do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  before do
    sign_in user if user
  end
  context "when an admin" do
    let(:user) { FactoryBot.create(:admin) }
    describe "POST /collections" do
      it "creates a collection" do
        post :create, params: { collection: { title: "test", slug: "slug", visibility: "open", description: "" } }

        expect(response).to be_redirect

        collection = query_service.find_all_of_model(model: Collection).first
        expect(collection.title).to eq ["test"]
        expect(collection.slug).to eq ["slug"]
        expect(collection.visibility).to eq ["open"]
        expect(collection.description).to eq []
      end
    end
    describe "GET /collections/new" do
      render_views
      it "renders a new record" do
        get :new

        expect(response).to render_template("base/_form")
        expect(response.body).to have_select "Owners"
      end
    end

    describe "GET /collections/edit" do
      render_views
      it "renders an existing record" do
        collection = persister.save(resource: FactoryBot.build(:collection))

        get :edit, params: { id: collection.id.to_s }

        expect(response.body).to have_field "Title", with: collection.title.first
      end
    end

    describe "PATCH /collections/:id" do
      it "updates an existing record" do
        collection = persister.save(resource: FactoryBot.build(:collection))

        patch :update, params: { id: collection.id.to_s, collection: { title: "New" } }
        reloaded = query_service.find_by(id: collection.id)

        expect(reloaded.title).to eq ["New"]
      end
    end

    describe "GET /concern/collections/:id/manifest" do
      it "returns a IIIF manifest for a collection" do
        collection = FactoryBot.create_for_repository(:collection)
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id)

        get :manifest, params: { id: collection.id.to_s, format: :json }
        manifest_response = MultiJson.load(response.body, symbolize_keys: true)

        expect(response.headers["Content-Type"]).to include "application/json"
        expect(manifest_response[:manifests].length).to eq 1
        expect(manifest_response[:manifests][0][:@id]).to eq "http://www.example.com/concern/scanned_resources/#{scanned_resource.id}/manifest"
      end
    end

    describe "GET /iiif/collections" do
      let(:collection) { FactoryBot.create_for_repository(:collection) }
      before do
        collection
      end
      it "returns a IIIF manifest of all collections" do
        get :index_manifest, params: { format: :json }
        manifest_response = MultiJson.load(response.body, symbolize_keys: true)

        expect(manifest_response[:@id]).to eq "http://www.example.com/iiif/collections"
        expect(manifest_response[:@type]).to eq "sc:Collection"
        expect(manifest_response[:label]).to eq "Figgy Collections"
        expect(manifest_response[:collections].length).to eq 1
        expect(manifest_response[:collections][0][:@id]).to eq "http://www.example.com/collections/#{collection.id}/manifest"
      end
    end
  end
end
