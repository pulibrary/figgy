# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
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

    allow_any_instance_of(MostRecentlyUpdatedFileSets).to receive(:most_recently_updated_file_sets).and_return [resource, resource2, resource3]
    allow_any_instance_of(LeastRecentlyUpdatedFileSets).to receive(:least_recently_updated_file_sets).and_return [resource3, resource2, resource]
  end

  describe "GET #fixity" do
    it "returns http success" do
      get :fixity
      expect(response).to have_http_status(:success)
    end

    it "sets most recently-updated filesets" do
      get :fixity
      expect(assigns[:recents].size).to eq 3
    end

    it "sets fixity failures" do
      get :fixity
      expect(assigns[:failures].size).to eq 1
    end

    it "sets least-recenty-updated filesets" do
      get :fixity
      expect(assigns[:upcoming].size).to eq 3
    end
  end
end
