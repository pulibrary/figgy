# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe NumismaticArtistsController, type: :controller do
  with_queue_adapter :inline
  let(:user) { nil }
  before do
    sign_in user if user
  end
  describe "new" do
    it_behaves_like "an access controlled new request"
  end
  describe "create" do
    let(:params) do
      {
        person: "artist person",
        role: "artist role"
      }
    end
    context "access control" do
      it_behaves_like "an access controlled create request"
    end
    context "adding to a parent issue" do
      let(:user) { FactoryBot.create(:admin) }
      let(:issue) { FactoryBot.create_for_repository(:numismatic_issue) }

      it "adds the id to the issue's artist ids and redirects to parent issue" do
        post :create, params: { numismatic_artist: params.merge(artist_parent_id: issue.id) }

        updated = Valkyrie.config.metadata_adapter.query_service.find_by(id: issue.id)
        expect(updated.numismatic_artist_ids).not_to be_empty
        expect(response).to redirect_to("http://test.host/catalog/#{issue.id}")
      end
    end
  end
  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    let(:numismatic_artist) { FactoryBot.create_for_repository(:numismatic_artist) }
    let(:issue) { FactoryBot.create(:numismatic_issue) }

    context "access control" do
      let(:factory) { :numismatic_artist }
      it_behaves_like "an access controlled destroy request"
    end

    it "redirects to the parent issue" do
      numismatic_artist = FactoryBot.create_for_repository(:numismatic_artist)
      issue = FactoryBot.create_for_repository(:numismatic_issue, numismatic_artist_ids: [numismatic_artist.id])

      delete :destroy, params: { id: numismatic_artist.id }
      expect(response).to redirect_to solr_document_path(issue)
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :numismatic_artist }
      it_behaves_like "an access controlled edit request"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :numismatic_artist }
      let(:extra_params) { { numismatic_artist: { person: ["Person 2"] } } }
      it_behaves_like "an access controlled update request"
    end
  end
end
