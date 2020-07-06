# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewerController do
  render_views

  describe "#index" do
    it "generates a hidden login container" do
      get :index

      expect(response.body).to have_selector "h1#title", visible: false
    end
    it "doesn't have an x-frame-options header" do
      get :index

      expect(response.headers["X-Frame-Options"]).to be_nil
    end
  end

  describe "#auth" do
    context "when the user is not logged in and could get access to the resource" do
      it "displays a sign in button" do
        resource = FactoryBot.create_for_repository(:complete_campus_only_scanned_resource)

        get :auth, params: { id: resource.id.to_s }

        expect(response.body).to have_link "Princeton Users: Log in to View"
      end
      it "doesn't have an x-frame-options header" do
        resource = FactoryBot.create_for_repository(:complete_campus_only_scanned_resource)

        get :auth, params: { id: resource.id.to_s }

        expect(response.headers["X-Frame-Options"]).to be_nil
      end
      context "and the resource is private" do
        it "redirects the user back to the viewer" do
          resource = FactoryBot.create_for_repository(:complete_private_scanned_resource)

          get :auth, params: { id: resource.id.to_s }

          expect(response).to redirect_to viewer_index_path(anchor: "?manifest=http://www.example.com/concern/scanned_resources/#{resource.id}/manifest")
        end
      end
      context "and the resource is CDL eligible" do
        it "displays a CDL-specific login button" do
          allow(CDL::EligibleItemService).to receive(:item_ids).with(source_metadata_identifier: "123456").and_return(["12345"])
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "123456")

          get :auth, params: { id: resource.id.to_s }

          expect(response).to be_success
          expect(response.body).to have_link "Princeton Users: Log In to Digitally Check Out"
        end
      end
    end
    context "when the user is logged in" do
      it "redirects back to the viewer" do
        sign_in FactoryBot.create(:user)
        resource = FactoryBot.create_for_repository(:complete_campus_only_scanned_resource)

        get :auth, params: { id: resource.id.to_s }

        expect(response).to redirect_to viewer_index_path(anchor: "?manifest=http://www.example.com/concern/scanned_resources/#{resource.id}/manifest")
      end
    end
  end
end
