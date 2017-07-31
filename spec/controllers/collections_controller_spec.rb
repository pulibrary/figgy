# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CollectionsController do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  before do
    sign_in user if user
  end
  context "when an admin" do
    let(:user) { FactoryGirl.create(:admin) }
    describe "POST /collections" do
      it "creates a collection" do
        post :create, params: { collection: { title: 'test', slug: 'slug', visibility: 'open', description: '' } }

        expect(response).to be_redirect

        collection = query_service.find_all_of_model(model: Collection).first
        expect(collection.title).to eq ['test']
        expect(collection.slug).to eq ['slug']
        expect(collection.visibility).to eq ['open']
        expect(collection.description).to eq []
      end
    end
    describe "GET /collections/new" do
      render_views
      it "renders a new record" do
        get :new

        expect(response).to render_template("valhalla/base/_form")
      end
    end

    describe "GET /collections/edit" do
      render_views
      it "renders an existing record" do
        collection = persister.save(resource: FactoryGirl.build(:collection))

        get :edit, params: { id: collection.id.to_s }

        expect(response.body).to have_field "Title", with: collection.title.first
      end
    end

    describe "PATCH /collections/:id" do
      it "updates an existing record" do
        collection = persister.save(resource: FactoryGirl.build(:collection))

        patch :update, params: { id: collection.id.to_s, collection: { title: 'New' } }
        reloaded = query_service.find_by(id: collection.id)

        expect(reloaded.title).to eq ['New']
      end
    end
  end
end
