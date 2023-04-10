# frozen_string_literal: true
require "rails_helper"

RSpec.describe DeletionMarkersController, type: :controller do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }

  before do
    sign_in user if user
  end

  describe "#destroy" do
    context "access control" do
      let(:factory) { :deletion_marker }
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a DeletionMarker" do
      deletion_marker = FactoryBot.create_for_repository(:deletion_marker)
      delete :destroy, params: { id: deletion_marker.id.to_s }

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: deletion_marker.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "#restore" do
    it "restores the resource" do
      allow(RestoreFromDeletionMarkerJob).to receive(:perform_later)
      deletion_marker = FactoryBot.create_for_repository(:deletion_marker)
      get :restore, params: { id: deletion_marker.id.to_s }
      expect(RestoreFromDeletionMarkerJob).to have_received(:perform_later).with(deletion_marker.id.to_s)
      expect(response).to be_redirect
    end
  end
end
