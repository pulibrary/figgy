# frozen_string_literal: true

require "rails_helper"

RSpec.describe FixityDashboardController, type: :controller do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }

  let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
  let(:resource2) { FactoryBot.create_for_repository(:scanned_resource) }
  let(:resource3) { FactoryBot.create_for_repository(:scanned_resource) }

  let(:file_metadata) { FileMetadata.new(fixity_success: 0) }

  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:change_set) { ScannedResourceChangeSet.new(resource) }
  let(:output) do
    change_set.files = [file]
    change_set_persister.save(change_set: change_set)
  end

  before do
    # they have to be saved to come out in the query
    file_set = query_service.find_members(resource: output).first
    file_set_change_set = FileSetChangeSet.new(file_set)
    file_set_change_set.validate(file_metadata: file_metadata)
    change_set_persister.save(change_set: file_set_change_set)
  end

  describe "GET #show" do
    let(:user) { FactoryBot.create(:admin) }
    before do
      sign_in user if user
    end

    it "returns http success" do
      get :show
      expect(response).to have_http_status(:success)
    end

    it "sets fixity failures variable" do
      get :show
      expect(assigns[:failures].size).to eq 1
    end

    context "most-recently-upated filesets" do
      before do
        allow_any_instance_of(FileSetsSortedByUpdated).to receive(:file_sets_sorted_by_updated).and_return [resource, resource2, resource3]
      end
      it "sets recents variable" do
        get :show
        expect(assigns[:recents].size).to eq 3
      end
    end

    context "least-recently-upated filesets" do
      before do
        allow_any_instance_of(FileSetsSortedByUpdated).to receive(:file_sets_sorted_by_updated).and_return [resource3, resource2, resource]
      end
      it "sets upcoming variable" do
        get :show
        expect(assigns[:upcoming].size).to eq 3
      end
    end

    context "for non-admin users" do
      let(:user) { nil }

      it "prevents viewing" do
        get :show
        expect(response).to be_redirect
      end
    end
  end
end
