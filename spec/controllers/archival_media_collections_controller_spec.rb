# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ArchivalMediaCollectionsController do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  before do
    sign_in user if user
  end

  it "creates the right kind of resource" do
    expect(described_class.resource_class).to eq ArchivalMediaCollection
  end

  context "when an admin" do
    let(:user) { FactoryBot.create(:admin) }

    describe "GET /archival_media_collections/new" do
      render_views
      it "renders a new record form" do
        get :new

        expect(response).to render_template("valhalla/base/_form")
      end
    end

    describe "POST /archival_media_collections" do
      let(:file) { File.open(Rails.root.join("spec", "fixtures", "some_finding_aid.xml"), 'r') }

      it "creates a collection and imports metadata" do
        stub_request(:get, "https://findingaids.princeton.edu/collections/AC044/c0003.xml?scope=record")
          .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Faraday v0.9.2' })
          .to_return(status: 200, body: file, headers: {})
        post :create, params: { archival_media_collection: { source_metadata_identifier: "AC044_c0003", refresh_remote_metadata: "0", bag_path: "/idk/some/path" } }

        expect(response).to be_redirect

        collection = query_service.find_all_of_model(model: ArchivalMediaCollection).first
        expect(collection.source_metadata_identifier).to eq ['AC044_c0003']
        expect(collection.primary_imported_metadata).to be_a ImportedMetadata
        expect(collection.title).to contain_exactly "Series 1: Committee Administration - Alumni Council: Proposals for Electing Young Alumni Trustees"
      end
    end
  end
end
