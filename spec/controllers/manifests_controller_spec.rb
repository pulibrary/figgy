# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestsController, type: :controller do
  describe "#v3" do
    context "with a ScannedMap" do
      it "renders a IIIF Presentation 3.0 manifest" do
        resource = FactoryBot.create_for_repository(:complete_open_scanned_map)
        get :v3, params: { id: resource.id, format: :json }
        manifest = JSON.parse(response.body)
        expect(manifest["@context"]).to include("http://iiif.io/api/presentation/3/context.json")
      end

      context "when given a local identifier" do
        it "still renders a IIIF Presentation 3.0 manifest" do
          resource = FactoryBot.create_for_repository(:complete_open_scanned_map, local_identifier: "pk643fd004")
          get :v3, params: { id: resource.local_identifier.first, format: :json }
          expect(response).to redirect_to manifest_v3_path(id: resource.id.to_s)
        end
      end
    end

    context "with a ScannedResource" do
      it "returns a 501" do
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource)
        get :v3, params: { id: resource.id, format: :json }
        expect(response.status).to eq 501
      end
    end
  end
end
