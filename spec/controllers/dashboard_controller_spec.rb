# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  describe "fixity dashboard" do
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie.config.storage_adapter }
    let(:query_service) { adapter.query_service }

    let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
    let(:resource2) { FactoryBot.create_for_repository(:scanned_resource) }
    let(:resource3) { FactoryBot.create_for_repository(:scanned_resource) }

    let(:file_metadata) { FileMetadata.new(fixity_success: 0) }

    let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
    let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
    let(:change_set) { ScannedResourceChangeSet.new(resource) }
    let(:output) do
      change_set.files = [file]
      change_set_persister.save(change_set: change_set)
    end

    before do
      # they have to be saved to come out in the query
      file_set = query_service.find_members(resource: output).first
      file_set_change_set = FileSetChangeSet.new(file_set)
      file_set.file_metadata = file_metadata
      change_set_persister.save(change_set: file_set_change_set)
    end

    it "returns http success" do
      get :fixity
      expect(response).to have_http_status(:success)
    end

    it "sets fixity failures variable" do
      get :fixity
      expect(assigns[:failures].size).to eq 1
    end

    context "most-recently-upated filesets" do
      before do
        allow_any_instance_of(FileSetsSortedByUpdated).to receive(:file_sets_sorted_by_updated).and_return [resource, resource2, resource3]
      end
      it "sets recents variable" do
        get :fixity
        expect(assigns[:recents].size).to eq 3
      end
    end

    context "least-recently-upated filesets" do
      before do
        allow_any_instance_of(FileSetsSortedByUpdated).to receive(:file_sets_sorted_by_updated).and_return [resource3, resource2, resource]
      end
      it "sets upcoming variable" do
        get :fixity
        expect(assigns[:upcoming].size).to eq 3
      end
    end
  end

  describe 'reports dashboard' do
    let(:user) { FactoryBot.create(:admin) }
    let(:resource) { FactoryBot.build(:scanned_resource, title: []) }
    let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, title: []) }
    let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
    let(:data) { "bibid,ark,title\n123456,ark:/99999/fk48675309,Earth rites : fertility rites in pre-industrial Britain\n" }

    before do
      sign_in user
      stub_bibdata(bib_id: '123456')
      stub_ezid(shoulder: "99999/fk4", blade: "8675309")

      change_set = ScannedResourceChangeSet.new(resource)
      change_set.validate(source_metadata_identifier: '123456')
      change_set.sync
      change_set_persister.save(change_set: change_set)
    end

    describe "GET #identifiers_to_reconcile" do
      it "displays a html view" do
        get :identifiers_to_reconcile
        expect(response).to render_template :identifiers_to_reconcile
      end
      it "allows downloading a CSV file" do
        get :identifiers_to_reconcile, format: 'csv'
        expect(response.body).to eq(data)
      end
    end
  end
end
