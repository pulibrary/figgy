# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileMetadataController do
  let(:user) {}
  before do
    sign_in user if user
  end

  describe "#destroy" do
    context "when not logged in" do
      it "redirects to login" do
        file_set = FactoryBot.create_for_repository(:video_file_set_with_caption)

        delete :destroy, params: { file_set_id: file_set.id, id: file_set.captions.first.id }

        expect(response).to redirect_to "http://test.host/users/auth/cas"
      end
    end
    context "when logged in" do
      let(:user) { FactoryBot.create(:admin) }
      it "deletes the FileMetadata and cleans the file from the repository" do
        file_set = FactoryBot.create_for_repository(:video_file_set_with_caption)
        caption = file_set.captions.first

        delete :destroy, params: { file_set_id: file_set.id, id: caption.id }

        resource = ChangeSetPersister.default.query_service.find_by(id: file_set.id)
        expect(resource.captions.length).to eq 0
        expect(CleanupFilesJob).to have_been_enqueued.with(file_identifiers: [caption.file_identifiers.first.to_s])
      end
      it "fails to delete a FileMetadata that's not a caption" do
        file_set = FactoryBot.create_for_repository(:video_file_set_with_caption)
        primary_file = file_set.primary_file

        delete :destroy, params: { file_set_id: file_set.id, id: primary_file }

        resource = ChangeSetPersister.default.query_service.find_by(id: file_set.id)
        expect(resource.primary_file).to be_present
        expect(CleanupFilesJob).not_to have_been_enqueued
      end
    end
  end

  describe "#new" do
    context "when not logged in" do
      it "redirects to login" do
        file_set = FactoryBot.create_for_repository(:video_file_set)

        get :new, params: { change_set: "caption", file_set_id: file_set.id.to_s }

        expect(response).to redirect_to "http://test.host/users/auth/cas"
      end
    end
    context "when logged in" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "renders a form" do
        file_set = FactoryBot.create_for_repository(:video_file_set)

        get :new, params: { change_set: "caption", file_set_id: file_set.id.to_s }

        expect(response.body).to have_content "Attach Caption"
      end
    end
  end
  describe "#create" do
    context "when not logged in" do
      it "redirects to login" do
        file_set = FactoryBot.create_for_repository(:video_file_set)

        post :create, params: { file_set_id: file_set.id.to_s }

        expect(response).to redirect_to "http://test.host/users/auth/cas"
      end
    end
    context "when logged in" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "renders new if given invalid parameters" do
        file_set = FactoryBot.create_for_repository(:video_file_set)

        post :create, params: {
          file_set_id: file_set.id.to_s,
          file_metadata: {
            change_set: "Caption",
            file: nil,
            caption_language: "eng"
          }
        }

        expect(response).to render_template "base/new"
      end
      it "creates a caption given valid parameters" do
        file_set = FactoryBot.create_for_repository(:video_file_set)

        post :create, params: {
          file_set_id: file_set.id.to_s,
          file_metadata: {
            change_set: "caption",
            file: fixture_file_upload("files/caption.vtt", "text/vtt"),
            caption_language: "eng"
          }
        }

        expect(response).to redirect_to solr_document_path(file_set.id.to_s)
        file_set = ChangeSetPersister.default.query_service.find_by(id: file_set.id)
        expect(file_set.captions.length).to eq 1
        expect(file_set.captions.first.file_identifiers).to be_present
        expect(file_set.captions.first.change_set).to eq "caption"
      end
    end
  end
end
