# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileMetadataController do
  let(:user) {}
  before do
    sign_in user if user
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
            change_set: "Caption",
            file: fixture_file_upload("files/caption.vtt", "text/vtt"),
            caption_language: "eng"
          }
        }

        expect(response).to redirect_to solr_document_path(file_set.id.to_s)
        file_set = ChangeSetPersister.default.query_service.find_by(id: file_set.id)
        expect(file_set.captions.length).to eq 1
        expect(file_set.captions.first.file_identifiers).to be_present
      end
    end
  end
end
