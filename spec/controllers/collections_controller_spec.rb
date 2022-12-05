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
    describe "DELETE /collection/:id" do
      it "doesn't let you delete a collection with members" do
        collection = FactoryBot.create_for_repository(:collection)
        FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id)

        delete :destroy, params: { id: collection.id.to_s }

        collection = query_service.find_by(id: collection.id)
        expect(collection).to be_present
        expect(flash["alert"]).to eq "Unable to delete a collection with members. Please transfer membership to another collection before deleting this collection."
        expect(response).to redirect_to "/collections/#{collection.id}"
      end
      it "can delete an empty collection" do
        collection = FactoryBot.create_for_repository(:collection)

        delete :destroy, params: { id: collection.id.to_s }

        expect { query_service.find_by(id: collection.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
        expect(flash["alert"]).to eq "Deleted Collection: #{collection.id}"
      end
    end
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

      it "creates a collection and imports metadata" do
        stub_findingaid(pulfa_id: "AC044_c0003")

        post :create, params: { collection: { source_metadata_identifier: "AC044_c0003", slug: "slug" } }

        expect(response).to be_redirect

        collection = query_service.find_all_of_model(model: Collection).first
        expect(collection.source_metadata_identifier).to eq ["AC044_c0003"]
        expect(collection.primary_imported_metadata).to be_a ImportedMetadata
        expect(collection.title).to contain_exactly "Alumni Council: Proposals for Electing Young Alumni Trustees"
      end

      context "with an ArchivalMediaCollection" do
        let(:file) { File.open(Rails.root.join("spec", "fixtures", "some_finding_aid.xml"), "r") }
        let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }

        before do
          stub_findingaid(pulfa_id: "AC044_c0003")
          allow(Dir).to receive(:exist?).and_return(true)
          allow(IngestArchivalMediaBagJob).to receive(:perform_later)
        end

        it "creates a collection and imports metadata and calls the ingest job" do
          post :create, params: { change_set: "archival_media_collection", collection: { source_metadata_identifier: "AC044_c0003", slug: "test-collection", refresh_remote_metadata: "0", bag_path: bag_path } }

          expect(response).to be_redirect

          collection = query_service.find_all_of_model(model: Collection).first
          expect(collection.change_set).to eq "archival_media_collection"
          expect(collection.source_metadata_identifier).to eq ["AC044_c0003"]
          expect(collection.primary_imported_metadata).to be_a ImportedMetadata
          expect(collection.title).to contain_exactly "Alumni Council: Proposals for Electing Young Alumni Trustees"
          expect(IngestArchivalMediaBagJob).to have_received(:perform_later)
        end
      end

      context "when source metadata identifier is not found in pulfalight" do
        it "" do
          stub_findingaid_error(pulfa_id: "AC000_c0000", status_code: 500)
          post :create, params: { collection: { source_metadata_identifier: "AC000_c0000", slug: "slug" } }

          # Does not redirect
          expect(response).not_to be_redirect
          expect(response).to render_template("base/new")

          # Does not create the collection
          collections = query_service.find_all_of_model(model: Collection)
          expect(collections).to be_empty
        end
      end

      context "when invalid form fields are submitted" do
        before do
          allow(Valkyrie.logger).to receive(:warn)
        end

        it "renders a new template and logs warnings" do
          post :create, params: { change_set: "archival_media_collection", collection: {} }

          expect(response.status).to eq(200)
          expect(response).to render_template(:new)
          expect(Valkyrie.logger).to have_received(:warn).with(
            {
              source_metadata_identifier: [
                error: :blank
              ],
              slug: [
                {
                  error: "contains invalid characters, please only use alphanumerics, dashes, and underscores"
                }
              ]
            }.to_s
          )
        end
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
      it "doesn't run a query for every member of the collection" do
        file = fixture_file_upload("files/example.tif", "image/tiff")
        collection = FactoryBot.create_for_repository(:collection)
        5.times do
          FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id, files: [file])
        end
        metadata_adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        allow(metadata_adapter.query_service).to receive(:find_by).and_call_original

        get :manifest, params: { id: collection.id.to_s, format: :json }

        expect(metadata_adapter.query_service).to have_received(:find_by).exactly(1).times
        manifest_response = MultiJson.load(response.body, symbolize_keys: true)

        expect(manifest_response[:manifests].length).to eq 5
      end
    end

    describe "GET /concern/collections/:id/manifest anonymously" do
      let(:user) { FactoryBot.create(:user) }
      it "returns a IIIF manifest for publically accessible manifests" do
        collection = FactoryBot.create_for_repository(:collection)
        FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id)
        scanned_resource2 = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_of_collection_ids: collection.id)

        get :manifest, params: { id: collection.id.to_s, format: :json }
        manifest_response = MultiJson.load(response.body, symbolize_keys: true)

        expect(response.headers["Content-Type"]).to include "application/json"
        expect(manifest_response[:manifests].length).to eq 1
        expect(manifest_response[:manifests][0][:@id]).to eq "http://www.example.com/concern/scanned_resources/#{scanned_resource2.id}/manifest"
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

    describe "show ark_report" do
      let(:collection) { FactoryBot.create_for_repository(:archival_media_collection, source_metadata_identifier: ["C0652"]) }
      let(:resource) { FactoryBot.create_for_repository(:complete_recording, title: []) }
      let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }

      before do
        stub_ezid(shoulder: "99999/fk4", blade: "7564298")
        stub_findingaid(pulfa_id: "C0652_c0377")

        change_set = RecordingChangeSet.new(resource)
        change_set.validate(source_metadata_identifier: "C0652_c0377", member_of_collection_ids: [collection.id])
        change_set_persister.save(change_set: change_set)
      end

      it "displays html" do
        get :ark_report, params: { id: collection.id }

        expect(response).to render_template :ark_report
      end

      it "allows downloading a CSV file" do
        get :ark_report, params: { id: collection.id, format: "csv" }
        data = "source_metadata_id,ark,manifest_url\nC0652_c0377,ark:/99999/fk47564298,http://test.host/concern/scanned_resources/#{resource.id}/manifest\n"

        expect(response.body).to eq(data)
      end
    end
  end

  context "when an anonymous user" do
    describe "show ark_report" do
      let(:collection) { FactoryBot.create_for_repository(:collection, source_metadata_identifier: ["C0652"], slug: "test-collection", state: "draft") }

      it "does not display" do
        get :ark_report, params: { id: collection.id }

        expect(response).to be_redirect
      end
    end
  end
end
