# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe NumismaticMonogramsController, type: :controller do
  with_queue_adapter :inline
  let(:user) { nil }
  before do
    sign_in user if user
  end
  describe "new" do
    it_behaves_like "an access controlled new request"
  end
  describe "create" do
    let(:valid_params) do
      {
        title: ["Monogram 1"]
      }
    end
    let(:invalid_params) do
      {
        title: nil
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
  end
  describe "destroy" do
    context "access control" do
      let(:factory) { :numismatic_monogram }
      it_behaves_like "an access controlled destroy request"
    end
  end
  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :numismatic_monogram }
      it_behaves_like "an access controlled edit request"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :numismatic_monogram }
      let(:extra_params) { { numismatic_monogram: { title: ["Monogram 2"] } } }
      it_behaves_like "an access controlled update request"
    end
  end
  describe "index" do
    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has lists all numismatic monograms" do
        FactoryBot.create_for_repository(:numismatic_monogram)

        get :index
        expect(response.body).to have_content "Test Monogram"
      end
    end
  end
  describe "manifest" do
    let(:user) { FactoryBot.create(:admin) }
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }

    it "returns a IIIF manifest for a monogram with a file" do
      monogram = FactoryBot.create_for_repository(:numismatic_monogram, files: [file])

      get :manifest, params: { id: monogram.id.to_s, format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:sequences].length).to eq 1
      expect(manifest_response[:viewingHint]).to eq "individuals"
    end

    it "returns an error message if the object doesn't exist" do
      get :manifest, params: { id: "asdf", format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:message]).to eq "No manifest found for asdf"
    end
  end
end
