# frozen_string_literal: true
require "rails_helper"
include FixtureFileUpload

RSpec.describe ScannedResourcesController, type: :controller do
  with_queue_adapter :inline
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:resource_klass) { ScannedResource }
  let(:manifestable_factory) { :complete_scanned_resource }

  before do
    sign_in user if user
  end

  it_behaves_like "a BaseResourceController"

  describe "new" do
    context "when not logged in but an auth token is given" do
      it "renders the full manifest" do
        resource = FactoryBot.create_for_repository(:complete_campus_only_scanned_resource)
        authorization_token = AuthToken.create!(group: ["admin"], label: "Admin Token")
        get :manifest, params: { id: resource.id, format: :json, auth_token: authorization_token.token }

        expect(response).to be_successful
        expect(response.body).not_to eq "{}"
      end
    end
    context "when not logged in" do
      it "returns a 403" do
        resource = FactoryBot.create_for_repository(:complete_private_scanned_resource)
        get :manifest, params: { id: resource.id, format: :json }
        expect(response).to be_forbidden
      end
      it "returns a 401 for a complete netid-required resource" do
        resource = FactoryBot.create_for_repository(:complete_campus_only_scanned_resource)
        get :manifest, params: { id: resource.id, format: :json }
        expect(response).to be_unauthorized
      end
    end
    context "when not logged, but in a reading room" do
      let(:config_hash) { { "access_control" => { "reading_room_ips" => ["1.2.3"] } } }
      before do
        # rubocop:disable RSpec/InstanceVariable
        @request.remote_addr = "1.2.3"
        # rubocop:enable RSpec/InstanceVariable
        allow(Figgy).to receive(:config).and_return(config_hash)
      end
      it "returns a 401" do
        resource = FactoryBot.create_for_repository(:reading_room_scanned_resource)
        get :manifest, params: { id: resource.id, format: :json }
        expect(response).to be_unauthorized
      end
    end
  end

  describe "change_set_class" do
    let(:user) { FactoryBot.create(:admin) }
    render_views

    context "when the params specify a change_set" do
      it "is simple, creates a new SimpleChangeSet" do
        get :new, params: { change_set: "simple" }
        expect(assigns(:change_set)).to be_a SimpleChangeSet
      end
      it "is recording, creates a new RecordingChangeSet" do
        get :new, params: { change_set: "recording" }
        expect(assigns(:change_set)).to be_a RecordingChangeSet
        expect(response.body).to have_field "Source Metadata ID"
        expect(response.body).to have_field "Title"
        expect(response.body).to have_selector "p.help-block", text: "Required if Source Metadata ID is blank"
      end
    end

    context "when the params specify an invalid change_set" do
      before do
        allow(Valkyrie.logger).to receive(:error)
      end
      it "creates a new ScannedResource and flashes a warning" do
        get :new, params: { change_set: "invalid" }
        expect(Valkyrie.logger).to have_received(:error).with("Failed to find the ChangeSet class for invalid.").at_least(:once)
      end
    end
  end

  describe "create" do
    let(:user) { FactoryBot.create(:admin) }
    let(:valid_params) do
      {
        title: ["Title 1", "Title 2"],
        rights_statement: RightsStatements.copyright_not_evaluated.to_s,
        visibility: "restricted"
      }
    end
    let(:invalid_params) do
      {
        title: [""],
        rights_statement: "Test Statement",
        visibility: "restricted"
      }
    end
    context "when asked to save and import" do
      before do
        allow(BrowseEverything).to receive(:config).and_return(
          file_system: {
            home: Rails.root.join("spec", "fixtures", "staged_files").to_s
          }
        )
        stub_bibdata(bib_id: "123456")
        stub_bibdata(bib_id: "4609321")
        stub_bibdata(bib_id: "1791261")
      end
      it "can create and import at once" do
        post :create, params: {
          scanned_resource: {
            source_metadata_identifier: "123456",
            rights_statement: RightsStatements.copyright_not_evaluated.to_s,
            visibility: "restricted"
          },
          commit: "Save and Ingest"
        }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
        resource = find_resource(id)

        expect(resource.member_ids.length).to eq 2
        members = query_service.find_members(resource: resource)
        expect(members.flat_map(&:title)).to eq ["1", "2"]
      end

      it "can create and import a MVW" do
        post :create, params: {
          scanned_resource: {
            source_metadata_identifier: "4609321",
            rights_statement: RightsStatements.copyright_not_evaluated.to_s,
            visibility: "restricted"
          },
          commit: "Save and Ingest"
        }

        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
        resource = find_resource(id)

        expect(resource.member_ids.length).to eq 2
        members = query_service.find_members(resource: resource)
        expect(members.flat_map(&:title)).to contain_exactly "Vol 1", "Vol 2"
      end

      context "when ingesting a directory with WAV files" do
        let(:tika_output) { tika_wav_output }
        it "can create and import audio reserves" do
          post :create, params: {
            scanned_resource: {
              source_metadata_identifier: "1791261",
              rights_statement: RightsStatements.copyright_not_evaluated.to_s,
              visibility: "restricted"
            },
            commit: "Save and Ingest"
          }

          expect(response).to be_redirect
          expect(response.location).to start_with "http://test.host/catalog/"
          id = response.location.gsub("http://test.host/catalog/", "").gsub("%2F", "/")
          resource = find_resource(id)

          expect(resource.member_ids.length).to eq 1
          file_set = find_resource(resource.member_ids.first)
          expect(file_set.file_metadata.length).to eq 3
          expect(file_set.title).to eq ["1791261_0701.wav"]
          expect(file_set.original_file).not_to be nil
          expect(file_set.original_file.label).to eq ["1791261_0701.wav"]
          expect(file_set.original_file.mime_type).to eq ["audio/x-wav"]
        end
      end
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource) }

    render_views

    it "does not render a collections form field" do
      get :edit, params: { id: scanned_resource.id.to_s }

      expect(response.body).to have_select "Collections", name: "scanned_resource[member_of_collection_ids][]"
    end

    context "when it has a member resource" do
      let(:member_resource) { FactoryBot.create_for_repository(:scanned_resource) }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [member_resource.id]) }

      before do
        scanned_resource
      end

      it "does not render a collections form field" do
        get :edit, params: { id: member_resource.id.to_s }

        expect(response.body).not_to have_select "Collections", name: "scanned_resource[member_of_collection_ids][]"
      end
    end
  end

  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html" do
      context "when it does exist" do
        it_behaves_like "a workflow controller", :scanned_resource
      end

      context "when the resource is locked for updates" do
        before do
          change_set_persister_mock = instance_double(ChangeSetPersister::Basic)
          allow(change_set_persister_mock).to receive(:metadata_adapter).and_return(described_class.change_set_persister.metadata_adapter)
          allow(change_set_persister_mock).to receive(:buffer_into_index).and_raise(Valkyrie::Persistence::StaleObjectError)
          allow(described_class).to receive(:change_set_persister).and_return(change_set_persister_mock)
        end

        it "notifies the user with an error and redirects them to the edit view" do
          resource = FactoryBot.create_for_repository(:scanned_resource)
          patch :update, params: { id: resource.id.to_s, scanned_resource: { title: ["Two"] } }

          expect(response).to render_template "base/edit"
          expect(flash[:alert]).to eq "Sorry, another user or process updated this resource simultaneously.  Please resubmit your changes."
        end
      end
    end

    context "when an attribute has leading / trailing spaces" do
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
      let(:params) do
        {
          source_metadata_identifier: " AC044_c0003 "
        }
      end
      it "strips them" do
        stub_pulfa(pulfa_id: "AC044_c0003")
        patch :update, params: { id: resource.id.to_s, scanned_resource: params }

        reloaded = find_resource(resource.id)
        expect(reloaded.source_metadata_identifier.first).to eq "AC044_c0003"
      end
    end

    context "when a published scanned resource has its title updated" do
      let(:existing_ark) { ["ark:/99999/fk4234567"] }
      let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, identifier: existing_ark) }
      let(:params) do
        {
          title: ["Updated scanned resource title"]
        }
      end
      before do
        sign_in user
      end

      context "when the resource has a PULFA ARK" do
        let(:minter) { class_double(Ezid::Identifier) }
        let(:minted_id) { instance_double(Ezid::Identifier) }
        let(:new_ark) { "ark:/99999/fk4345678" }
        before do
          allow(minted_id).to receive(:id).and_return(new_ark)
          allow(minter).to receive(:mint).and_return(minted_id)
          stub_request(:head, "http://n2t.institution.edu/path").to_return(status: 302, headers: { "location" => "http://findingaids.princeton.edu/path" })
          stub_request(:head, "http://arks.princeton.edu/ark:/99999/fk4234567").to_return(status: 301, headers: { "location" => "http://n2t.institution.edu/path" })

          allow(IdentifierService).to receive(:minter).and_return(minter)
          allow(IdentifierService).to receive(:minter_user).and_return("spec")
        end
        it "does not update the ARK and persists the other updates" do
          patch :update, params: { id: resource.id.to_s, scanned_resource: params }

          expect(response).to redirect_to(solr_document_path(resource.id))

          reloaded = find_resource(resource.id)
          expect(reloaded.identifier).to eq existing_ark
          expect(reloaded.title).to eq ["Updated scanned resource title"]
        end
      end
    end

    context "when a published simple resource has its title updated" do
      let(:existing_ark) { ["ark:/99999/fk4234567"] }
      let(:resource) { FactoryBot.create_for_repository(:complete_simple_resource, identifier: existing_ark) }
      let(:params) do
        {
          title: ["Updated simple resource title"]
        }
      end
      before do
        sign_in user
      end

      context "when the resource has a PULFA ARK" do
        it "alerts the client to an ARK update error but persists the other updates" do
          patch :update, params: { id: resource.id.to_s, scanned_resource: params }

          expect(response).to redirect_to(solr_document_path(resource.id))

          reloaded = find_resource(resource.id)
          expect(reloaded.identifier).to eq existing_ark
          expect(reloaded.title).to eq ["Updated simple resource title"]
        end
      end

      context "when updating logical structure" do
        it "works" do
          sign_in user
          resource = FactoryBot.create_for_repository(:scanned_resource)
          structure = {
            "logical_structure" =>
            [{ "nodes" =>
               [{ "label" => "Test", "nodes" => [{ "proxy" => "641b8b7a-52c7-4909-8ee8-36735fb5c52f" }] },
                { "proxy" => "9aa2123a-553b-4d06-a06a-f39c936c47ba" }],
               "label" => "Logical" }]
          }
          patch :update, params: { id: resource.id.to_s, scanned_resource: structure }

          expect(response).to redirect_to(solr_document_path(resource.id))

          reloaded = find_resource(resource.id)
          expect(reloaded.logical_structure.first.nodes.first.label).to eq ["Test"]
        end
      end
    end
  end

  describe "structure" do
    let(:user) { FactoryBot.create(:admin) }
    context "when not logged in" do
      let(:user) { nil }
      it "redirects to login or root" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)

        get :structure, params: { id: scanned_resource.id.to_s }
        expect(response).to be_redirect
      end
    end
    context "when a scanned resource doesn't exist" do
      it "raises an error" do
        get :structure, params: { id: "banana" }
        expect(response).to redirect_to_not_found
      end
    end
    context "when it does exist" do
      render_views
      it "renders a structure editor form" do
        file_set = FactoryBot.create_for_repository(:file_set)
        scanned_resource = FactoryBot.create_for_repository(
          :scanned_resource,
          member_ids: file_set.id,
          thumbnail_id: file_set.id,
          logical_structure: [
            { label: "testing", nodes: [{ label: "Chapter 1", nodes: [{ proxy: file_set.id }] }] }
          ]
        )

        query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
        allow(query_service).to receive(:find_by).with(id: scanned_resource.id).and_call_original
        allow(query_service).to receive(:find_inverse_references_by)
        get :structure, params: { id: scanned_resource.id.to_s }

        expect(response.body).to have_selector "li[data-proxy='#{file_set.id}']"
        expect(response.body).to have_field("label", with: "Chapter 1")
        expect(response.body).to have_link scanned_resource.title.first, href: solr_document_path(id: scanned_resource.id)
        expect(query_service).not_to have_received(:find_inverse_references_by)
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end

  context "when an admin" do
    let(:user) { FactoryBot.create(:admin) }

    # This block tests functionality defined in `app/controllers/concerns/browse_everythingable.rb`
    #   Acts as a 'master spec' in this regard
    describe "POST /concern/scanned_resources/:id/browse_everything_files" do
      let(:file) { File.open(Rails.root.join("spec", "fixtures", "files", "example.tif")) }
      let(:bytestream) { instance_double(ActiveStorage::Blob) }
      let(:upload_file) { double }
      let(:upload_file_id) { "test-upload-file-id" }
      let(:upload) { instance_double(BrowseEverything::Upload) }
      let(:uploads) { [upload.id] }
      let(:upload_id) { "test-upload-id" }
      let(:params) do
        {
          "id": resource.id,
          "browse_everything" => { "uploads" => uploads }
        }
      end
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }

      before do
        allow(upload_file).to receive(:purge_bytestream)
        allow(upload_file).to receive(:download).and_return(file.read)
        allow(upload_file).to receive(:bytestream).and_return(bytestream)
        allow(upload_file).to receive(:name).and_return("example.tif")
        allow(upload_file).to receive(:id).and_return(upload_file_id)
        allow(BrowseEverything::UploadFile).to receive(:find).and_return([upload_file])
        allow(upload).to receive(:files).and_return([upload_file])
        allow(upload).to receive(:id).and_return(upload_id)
        allow(BrowseEverything::Upload).to receive(:find_by).and_return([upload])
      end

      context "when given an empty array of selected files" do
        let(:uploads) { [] }

        it "doesn't upload anything" do
          post :browse_everything_files, params: params
          reloaded = adapter.query_service.find_by(id: resource.id)

          expect(response).to be_redirect
          expect(reloaded.member_ids.length).to eq 0
        end
      end

      context "when a server-side error is encountered while downloading a file" do
        before do
          allow(upload_file).to receive(:download).and_raise(StandardError)
        end

        it "does not persist any files" do
          post :browse_everything_files, params: params
          reloaded = adapter.query_service.find_by(id: resource.id)

          expect(response).to be_redirect
          expect(reloaded.member_ids).to be_empty
        end
      end
      it "uploads files" do
        # Ensure that indexing is always safe and done at the end.
        allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(Valkyrie::MetadataAdapter.find(:index_solr).persister)
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save).and_call_original
        allow(Valkyrie::MetadataAdapter.find(:index_solr).persister).to receive(:save_all).and_call_original

        post :browse_everything_files, params: params
        reloaded = adapter.query_service.find_by(id: resource.id)

        expect(reloaded.member_ids.length).to eq 1
        expect(reloaded.pending_uploads).to be_empty
        expect(Valkyrie::MetadataAdapter.find(:index_solr).persister).not_to have_received(:save)
        expect(Valkyrie::MetadataAdapter.find(:index_solr).persister).to have_received(:save_all).at_least(1).times

        file_sets = Valkyrie.config.metadata_adapter.query_service.find_members(resource: reloaded)
        expect(file_sets.first.file_metadata.length).to eq 3
      end

      context "when the pending uploads have file URIs for hidden files" do
        let(:upload_file2) { double }
        let(:upload_file_id2) { "test-upload-file-id2" }
        before do
          allow(upload_file2).to receive(:name).and_return(".hidden.tif")
          allow(upload_file2).to receive(:id).and_return(upload_file_id2)

          allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file_id2]).and_return([upload_file2])
          allow(BrowseEverything::UploadFile).to receive(:find).with([upload_file_id]).and_return([upload_file])
          allow(upload).to receive(:files).and_return([upload_file, upload_file2])
        end

        it "filters the uploads" do
          post :browse_everything_files, params: params
          reloaded = adapter.query_service.find_by(id: resource.id)

          expect(reloaded.member_ids.length).to eq 1
          expect(reloaded.decorate.file_sets.first.title).to eq [File.basename(file.path)]
        end
      end
    end
  end

  describe "GET /concern/scanned_resources/save_and_ingest/:id" do
    let(:user) { FactoryBot.create(:admin) }
    before do
      allow(BrowseEverything).to receive(:config).and_return(
        file_system: {
          home: Rails.root.join("spec", "fixtures", "staged_files").to_s
        }
      )
    end
    it "returns JSON for whether a directory exists" do
      get :save_and_ingest, params: { format: :json, id: "123456" }

      output = JSON.parse(response.body, symbolize_keys: true)

      expect(output["exists"]).to eq true
      expect(output["location"]).to eq "Santa/ready/123456"
      expect(output["file_count"]).to eq 2
    end
    it "returns JSON for when it's a MVW" do
      get :save_and_ingest, params: { format: :json, id: "4609321" }

      output = JSON.parse(response.body, symbolize_keys: true)

      expect(output["exists"]).to eq true
      expect(output["location"]).to eq "Santa/ready/4609321"
      expect(output["file_count"]).to eq 0
      expect(output["volume_count"]).to eq 2
    end
    context "when ingesting a music reserve" do
      it "uses the music directory" do
        get :save_and_ingest, params: { change_set: "recording", format: :json, id: "1182238" }

        output = JSON.parse(response.body, symbolize_keys: true)

        expect(output["exists"]).to eq true
        expect(output["location"]).to eq "cd-14000-14999/1182238"
        expect(output["file_count"]).to eq 2
      end
    end
    context "when a folder doesn't exist" do
      it "returns JSON appropriately" do
        get :save_and_ingest, params: { format: :json, id: "1234" }

        output = JSON.parse(response.body, symbolize_keys: true)

        expect(output["exists"]).to eq false
        expect(output["location"]).to be_nil
        expect(output["file_count"]).to be_nil
      end
    end
  end
end
