# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::CoinsController, type: :controller do
  with_queue_adapter :inline
  let(:user) { nil }
  before do
    sign_in user if user
  end
  describe "new" do
    it_behaves_like "an access controlled new request"
    render_views
    it "is created in an issue" do
      issue = FactoryBot.create_for_repository(:numismatic_issue)
      get :new, params: { parent_id: issue.id.to_s }

      expect(assigns(:selected_issue)).to be_truthy
    end
  end
  describe "create" do
    let(:valid_params) do
      {
        size: [5],
        visibility: "restricted"
      }
    end
    let(:invalid_params) do
      {
        size: [5]
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end

    context "coin is created in the context of an issue" do
      let(:issue) { FactoryBot.create_for_repository(:numismatic_issue) }
      let(:user) { FactoryBot.create(:admin) }

      before do
        sign_in user
      end

      it "adds the coin as a member of the issue" do
        post :create, params: { numismatics_coin: { append_id: issue.id.to_s, weight: 5 } }

        updated_issue = Valkyrie.config.metadata_adapter.query_service.find_by(id: issue.id)
        expect(updated_issue.member_ids).not_to be_empty
      end
    end
  end
  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    let(:coin) { FactoryBot.create_for_repository(:coin) }
    let(:issue) { FactoryBot.create_for_repository(:numismatic_issue) }
    context "access control" do
      let(:factory) { :coin }
      it_behaves_like "an access controlled destroy request"
    end

    it "redirects to the parent issue" do
      coin = FactoryBot.create_for_repository(:coin)
      issue = FactoryBot.create_for_repository(:numismatic_issue, member_ids: [coin.id])
      delete :destroy, params: { id: coin.id }
      expect(response).to redirect_to solr_document_path(issue)
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :coin }
      it_behaves_like "an access controlled edit request"
    end
    let(:resource) { FactoryBot.create_for_repository(:coin) }
    it "retrieves an array of facet values to for use in populating select boxes" do
      metadata_adapter = Valkyrie::MetadataAdapter.find(:index_solr)
      change_set_persister = ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter)
      coin = FactoryBot.create_for_repository(:coin,
                                              numismatic_collection: "numismatic collection")
      change_set = ChangeSet.for(coin)
      change_set_persister.save(change_set: change_set)

      get :edit, params: { id: resource.id.to_s }
      numismatic_collections = assigns(:numismatic_collections)

      expect(numismatic_collections.first.value).to eq "numismatic collection"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :coin }
      let(:extra_params) { { coin: { size: [6] } } }
      it_behaves_like "an access controlled update request"
    end
  end
  describe "GET /concern/coins/:id/manifest" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    before do
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "returns a IIIF manifest for a resource with a file" do
      coin = FactoryBot.create_for_repository(:complete_open_coin, files: [file])

      get :manifest, params: { id: coin.id.to_s, format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:sequences].length).to eq 1
      expect(manifest_response[:viewingHint]).to eq "individuals"
    end
  end
  describe "auto ingest" do
    let(:user) { FactoryBot.create(:admin) }
    let(:coin) { FactoryBot.create_for_repository(:complete_open_coin, coin_number: coin_number) }
    let(:staged_files) { Rails.root.join("spec", "fixtures", "staged_files") }
    before do
      allow(BrowseEverything).to receive(:config).and_return(fast_file_system: { home: staged_files.to_s })
      allow(IngestFolderJob).to receive(:perform_later)
    end

    context "when a folder exists" do
      let(:coin_number) { 1234 }
      let(:ingest_dir) { staged_files.join("numismatics", "1234") }
      let(:args) { { directory: ingest_dir.to_s, property: "id", id: coin.id.to_s } }

      it "returns JSON for whether a directory exists" do
        get :discover_files, params: { format: :json, id: coin.id }

        output = JSON.parse(response.body, symbolize_keys: true)

        expect(output["exists"]).to eq true
        expect(output["location"]).to eq "1234"
        expect(output["file_count"]).to eq 2
      end
      it "spawns a background job to ingest the files" do
        post :auto_ingest, params: { id: coin.id }
        expect(IngestFolderJob).to have_received(:perform_later).with(args)
      end
    end
    context "when a folder doesn't exist" do
      let(:coin_number) { 6789 }
      it "returns JSON appropriately" do
        get :discover_files, params: { format: :json, id: coin.id }

        output = JSON.parse(response.body, symbolize_keys: true)

        expect(output["exists"]).to eq false
        expect(output["location"]).to be_nil
        expect(output["file_count"]).to be_nil
      end
    end
  end
  describe "GET /coins/:id/orangelight" do
    let(:user) { FactoryBot.create(:admin) }

    it "renders an orangelight document" do
      coin = FactoryBot.create_for_repository(:coin)
      FactoryBot.create_for_repository(:numismatic_issue, member_ids: [coin.id])
      get :orangelight, params: { id: coin.id, format: :json }
      doc = JSON.parse(response.body)
      expect(doc["id"]).to eq "coin-#{coin.coin_number}"
    end
  end

  # Copied from ephemera_folders_controller_spec.rb:434. Similarly the test will fail if the stubbing is not included.
  describe "pdf" do
    let(:resource) { FactoryBot.create_for_repository(:coin, member_ids: [file_set.id]) }
    let(:user) { FactoryBot.create(:admin) }
    let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: file_metadata) }
    let(:file_metadata) { FileMetadata.new(mime_type: "image/tiff", use: Valkyrie::Vocab::PCDMUse.OriginalFile) }
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }

    let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:pdf_file) do
      file = fixture_file_upload("files/example.tif", "application/pdf")
      node = FileMetadata.for(file: file).new(id: SecureRandom.uuid)
      stored_file = storage_adapter.upload(resource: node, file: file, original_filename: "tmp.pdf")
      node.file_identifiers = stored_file.id
      node
    end
    let(:pdf_generator) { double }

    before do
      allow(PDFGenerator).to receive(:new).and_return(pdf_generator)
      allow(pdf_generator).to receive(:render).and_return(pdf_file)
    end

    it "generates a pdf, attaches it to the folder, and redirects the user to download it" do
      get :pdf, params: { id: resource.id.to_s }
      reloaded = adapter.query_service.find_by(id: resource.id)
      expect(response).to redirect_to Rails.application.routes.url_helpers.download_path(resource_id: resource.id.to_s, id: reloaded.pdf_file.id.to_s)

      expect(reloaded.file_metadata).not_to be_blank
      expect(reloaded.pdf_file).not_to be_blank
    end
  end

  # TODO: remove this block when stubbing above has been removed
  context "coverage for lines skipped because of stubbing" do
    it "has a storage adapter" do
      expect(controller.storage_adapter).to be_a(InstrumentedStorageAdapter)
    end
  end
end
