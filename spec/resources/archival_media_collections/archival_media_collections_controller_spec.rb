# frozen_string_literal: true
require "rails_helper"

RSpec.describe ArchivalMediaCollectionsController, type: :controller do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  before do
    sign_in user if user
  end

  it "creates the right kind of resource" do
    expect(described_class.resource_class).to eq ArchivalMediaCollection
  end

  describe "new" do
    render_views
    it "renders a new record form" do
      get :new

      expect(response).to render_template("base/_form")
    end
  end

  describe "create" do
    let(:file) { File.open(Rails.root.join("spec", "fixtures", "some_finding_aid.xml"), "r") }
    let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }

    before do
      stub_pulfa(pulfa_id: "AC044/c0003")
      allow(Dir).to receive(:exist?).and_return(true)
      allow(IngestArchivalMediaBagJob).to receive(:perform_later)
    end

    it "creates a collection and imports metadata and calls the ingest job" do
      post :create, params: { archival_media_collection: { source_metadata_identifier: "AC044_c0003", refresh_remote_metadata: "0", bag_path: bag_path } }

      expect(response).to be_redirect

      collection = query_service.find_all_of_model(model: ArchivalMediaCollection).first
      expect(collection.source_metadata_identifier).to eq ["AC044_c0003"]
      expect(collection.primary_imported_metadata).to be_a ImportedMetadata
      expect(collection.title).to contain_exactly "Alumni Council: Proposals for Electing Young Alumni Trustees"
      expect(IngestArchivalMediaBagJob).to have_received(:perform_later)
    end
  end
end
