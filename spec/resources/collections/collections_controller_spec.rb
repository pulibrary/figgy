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

      it "creates a collection and imports metadata" do
        stub_pulfa(pulfa_id: "AC044_c0003")

        post :create, params: { collection: { source_metadata_identifier: "AC044_c0003", slug: "slug" } }

        expect(response).to be_redirect

        collection = query_service.find_all_of_model(model: Collection).first
        expect(collection.source_metadata_identifier).to eq ["AC044_c0003"]
        expect(collection.primary_imported_metadata).to be_a ImportedMetadata
        expect(collection.title).to contain_exactly "Alumni Council: Proposals for Electing Young Alumni Trustees"
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

      context "with an ArchivalMediaCollection" do
        describe "create" do
          let(:file) { File.open(Rails.root.join("spec", "fixtures", "some_finding_aid.xml"), "r") }
          let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }

          before do
            stub_pulfa(pulfa_id: "AC044_c0003")
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

        describe "create" do
          before do
            allow(Valkyrie.logger).to receive(:warn)
          end

          it "creates a collection and imports metadata and calls the ingest job" do
            post :create, params: { change_set: "archival_media_collection", collection: {} }

            expect(response.status).to eq(200)
            expect(response).to render_template(:new)
            expect(Valkyrie.logger).to have_received(:warn).with(
              source_metadata_identifier: [
                error: "can't be blank"
              ],
              slug: [
                {
                  error: "contains invalid characters, please only use alphanumerics, dashes, and underscores"
                }
              ]
            )
          end
        end
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
      let(:resource) { FactoryBot.create_for_repository(:complete_media_resource, title: []) }
      let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }

      before do
        stub_ezid(shoulder: "99999/fk4", blade: "7564298")
        stub_pulfa(pulfa_id: "C0652_c0377")

        change_set = MediaResourceChangeSet.new(resource)
        change_set.validate(source_metadata_identifier: "C0652_c0377", member_of_collection_ids: [collection.id])
        change_set_persister.save(change_set: change_set)
      end

      it "displays html" do
        get :ark_report, params: { id: collection.id }

        expect(response).to render_template :ark_report
      end

      it "allows downloading a CSV file" do
        get :ark_report, params: { id: collection.id, format: "csv" }
        data = "source_metadata_id,ark,manifest_url\nC0652_c0377,ark:/99999/fk47564298,http://test.host/concern/media_resources/#{resource.id}/manifest\n"

        expect(response.body).to eq(data)
      end
    end

    describe "POST /collections/:id/browse_everything_files" do
      let(:file1) { File.open(Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag", "bagit.txt")) }
      let(:file2) { File.open(Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag", "data", "32101047382401.xml")) }
      let(:selected_files) do
        {
          "0" => {
            "url" => "file://#{file1.path}",
            "file_name" => File.basename(file1.path),
            "file_size" => file1.size,
            "directory" => false
          },
          "1" => {
            "url" => "file://#{file2.path}",
            "file_name" => File.basename(file2.path),
            "file_size" => file2.size,
            "directory" => false
          }
        }
      end
      let(:params) do
        {
          "selected_files" => selected_files
        }
      end

      before do
        stub_pulfa(pulfa_id: "C0652")
        stub_pulfa(pulfa_id: "C0652_c0377")
      end

      it "uploads files" do
        resource = FactoryBot.create_for_repository(:collection, change_set: "archival_media_collection", source_metadata_identifier: "C0652")

        post :browse_everything_files, params: { id: resource.id, selected_files: params["selected_files"] }
        expect(response).to redirect_to("/catalog/#{resource.id}")
        expect(flash[:notice]).to have_text("Archival bags have been enqueued for ingestion in this collection.")
        reloaded = adapter.query_service.find_by(id: resource.id)

        expect(reloaded.decorate.members.length).to eq 1
        expect(reloaded.decorate.members.first).to be_a ScannedResource
        member = reloaded.decorate.members.first
        expect(member.decorate.file_sets).to be_empty

        expect(member.decorate.members.length).to eq 1
        volume = member.decorate.members.first

        expect(volume.decorate.file_sets.length).to eq 4
        titles = volume.decorate.file_sets.map(&:title)
        titles.flatten!
        expect(titles).to include("32101047382401_2", "32101047382401_1", "32101047382401.xml", "32101047382401_AssetFront.jpg")
        file_metadata = volume.decorate.file_sets.map(&:file_metadata)
        file_metadata.flatten!
        file_use_uris = file_metadata.map(&:use)
        file_use_uris.flatten!
        expect(file_use_uris).to include(
          Valkyrie::Vocab::PCDMUse.OriginalFile,
          Valkyrie::Vocab::PCDMUse.ServiceFile,
          Valkyrie::Vocab::PCDMUse.IntermediateFile,
          Valkyrie::Vocab::PCDMUse.PreservationMasterFile
        )
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
