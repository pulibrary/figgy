# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkEditController, type: :controller do
  let(:user) { FactoryBot.create(:admin) }
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter) }
  let(:collection) { FactoryBot.create_for_repository(:collection, title: ["The Important Person's Things"]) }
  let(:collection_title) { ["The Important Person's Things"] }
  let(:resource1) { FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id, title: "Resource 1 - Significant") }
  let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id, title: "Resource 2 - Significant") }
  let(:state) { ["pending"] }
  let(:params) { {f: {member_of_collection_titles_ssim: collection_title, state_ssim: state}, q: "significant"} }
  before do
    sign_in user
    change_set_persister.save(change_set: ChangeSet.for(collection))
    change_set_persister.save(change_set: ChangeSet.for(resource1))
    change_set_persister.save(change_set: ChangeSet.for(resource2))
  end
  describe "GET /bulk_edit" do
    render_views
    it "renders the selected " do
      get :resources_edit, params: params
      expect(response.body).to have_content("Bulk edit 2 resources")
      expect(response.body).to have_field("mark_complete")
    end
  end

  describe "POST /bulk_edit" do
    let(:params) { {mark_complete: "1", search_params: {f: {member_of_collection_titles_ssim: collection_title, state_ssim: state}, q: "significant"}} }
    before do
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "updates the resources" do
      expect { post :resources_update, params: params }.to have_enqueued_job(BulkUpdateJob).with(ids: [resource2.id.to_s, resource1.id.to_s], args: {mark_complete: true})
      expect(response.body).to redirect_to root_path
      expect(flash[:notice]).to eq "2 resources were queued for bulk update."
    end

    context "when there are multiple pages of results" do
      let(:params) { {batch_size: 1, mark_complete: "1", search_params: {f: {member_of_collection_titles_ssim: collection_title, state_ssim: state}, q: ""}} }
      it "enqueues one update job per page of results" do
        post :resources_update, params: params
        expect(BulkUpdateJob).to have_been_enqueued.with(ids: [resource1.id.to_s], args: {mark_complete: true})
        expect(BulkUpdateJob).to have_been_enqueued.with(ids: [resource2.id.to_s], args: {mark_complete: true})
      end
    end
  end
end
