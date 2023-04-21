# frozen_string_literal: true
require "rails_helper"

RSpec.describe FixityDashboardController, type: :controller do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }

  let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
  let(:resource2) { FactoryBot.create_for_repository(:scanned_resource) }
  let(:resource3) { FactoryBot.create_for_repository(:scanned_resource) }

  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:change_set) { ScannedResourceChangeSet.new(resource) }
  let(:output) do
    change_set.files = [file]
    change_set_persister.save(change_set: change_set)
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

    context "for non-admin users" do
      let(:user) { nil }

      it "prevents viewing" do
        get :show
        expect(response).to be_redirect
      end
    end
  end
end
