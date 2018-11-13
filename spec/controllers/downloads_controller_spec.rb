# frozen_string_literal: true
require "rails_helper"

RSpec.describe DownloadsController do
  let(:meta) { Valkyrie.config.metadata_adapter }
  let(:disk) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: meta, storage_adapter: disk) }
  let(:sample_file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [sample_file]) }
  let(:file_set) { resource.member_ids.map { |id| meta.query_service.find_by(id: id) }.first }
  let(:file_node) { file_set.file_metadata.first }
  let(:user) { FactoryBot.create(:admin) }

  describe "GET /downloads/:obj/file/:id" do
    context "when logged in" do
      before do
        sign_in user if user
      end

      it "serves files that exist" do
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }
        expect(response.body).to eq(sample_file.read)
        expect(response.content_length).to eq(196_882)
        expect(response.content_type).to eq("image/tiff")
        expect(response.headers["Content-Disposition"]).to eq('inline; filename="example.tif"')
      end

      it "returns an 404 when the file_set doesn't exist" do
        get :show, params: { resource_id: file_set.id.to_s, id: "bogus" }
        expect(response.status).to eq(404)
      end

      it "returns an 404 when the file is not found on disk" do
        allow(disk).to receive(:find_by).and_raise(Valkyrie::StorageAdapter::FileNotFound)
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }
        expect(response.status).to eq(404)
      end

      it "returns an appropriate error when the resource doesn't exist" do
        get :show, params: { resource_id: "bogus", id: "bogus" }
        expect(response.status).to eq(404)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }
        expect(response).to redirect_to("/users/auth/cas")
      end
    end

    context "with an auth token" do
      it "allows downloading the file" do
        token = AuthToken.create!(group: ["admin"], label: "admin_token")
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s, auth_token: token.token }
        expect(response.content_length).to eq(196_882)
        expect(response.content_type).to eq("image/tiff")
        expect(response.body).to eq(sample_file.read)
      end
    end
  end
end
