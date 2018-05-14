# frozen_string_literal: true
require "rails_helper"

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
      let(:file) { File.open(Rails.root.join("spec", "fixtures", "some_finding_aid.xml"), "r") }

      before do
        allow(Dir).to receive(:exist?).and_return(true)
      end

      it "creates a collection and imports metadata" do
        stub_pulfa(pulfa_id: "AC044/c0003")
        allow(IngestArchivalMediaBagJob).to receive(:perform_later)
        post :create, params: { archival_media_collection: { source_metadata_identifier: "AC044_c0003", refresh_remote_metadata: "0", bag_path: "/idk/some/path" } }

        expect(response).to be_redirect

        collection = query_service.find_all_of_model(model: ArchivalMediaCollection).first
        expect(collection.source_metadata_identifier).to eq ["AC044_c0003"]
        expect(collection.primary_imported_metadata).to be_a ImportedMetadata
        expect(collection.title).to contain_exactly "Series 1: Committee Administration - Alumni Council: Proposals for Electing Young Alumni Trustees"
        expect(IngestArchivalMediaBagJob).to have_received(:perform_later).with(collection_component: "AC044_c0003", bag_path: "/idk/some/path", user: user)
      end
    end

    describe "GET /archival_media_collections/[id]/ark_report" do
      let(:collection) { FactoryBot.create_for_repository(:archival_media_collection, source_metadata_identifier: ["C0652"]) }
      let(:resource) { FactoryBot.build(:published_media_resource, title: []) }
      let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
      let(:data) { "ark,component_id\nark:/99999/fk47564298,C0652_c0377\n" }

      before do
        stub_ezid(shoulder: "99999/fk4", blade: "7564298")
        stub_pulfa(pulfa_id: "C0652_c0377")

        change_set = MediaResourceChangeSet.new(resource)
        change_set.validate(source_metadata_identifier: "C0652_c0377", member_of_collection_ids: [collection.id])
        change_set.sync
        change_set_persister.save(change_set: change_set)
      end

      it "displays html" do
        get :ark_report, params: { id: collection.id }

        expect(response).to render_template :ark_report
      end

      it "allows downloading a CSV file" do
        get :ark_report, params: { id: collection.id, format: "csv" }

        expect(response.body).to eq(data)
      end
    end
  end
end
