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
      context "and the resource is in a restricted viewership collection" do
        it "displays a restricted viewer specific login button" do
          collection = FactoryBot.create_for_repository(:collection, restricted_viewers: ["tpend"])
          resource = FactoryBot.create_for_repository(:complete_reading_room_scanned_resource, member_of_collection_ids: collection.id)

          get :auth, params: { id: resource.id.to_s }

          expect(response).to be_successful
          expect(response.body).to have_content "Access to this material is limited to specific classes. Use your Princeton credentials to login."
          expect(response.body).to have_link "Login"
        end
      end
      context "and the resource is CDL eligible" do
        it "displays a CDL-specific login button" do
          allow(CDL::EligibleItemService).to receive(:item_ids).with(source_metadata_identifier: "123456").and_return(["12345"])
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "123456")

          get :auth, params: { id: resource.id.to_s }

          expect(response).to be_successful
          expect(response.body).to have_link "Princeton Users: Log in to check out a digital copy"
        end
      end
    end
    context "for a logged in user on a CDL eligible item" do
      context "when the item is available" do
        it "displays a copyright statement and a check-out button" do
          user = FactoryBot.create(:user)
          allow(CDL::EligibleItemService).to receive(:item_ids).with(source_metadata_identifier: "123456").and_return(["12345"])
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "123456")
          sign_in user

          get :auth, params: { id: resource.id.to_s }

          expect(response).to be_successful
          expect(response.body).to have_content "This Item may be protected by third-party copyright and/or related intellectual property rights."
          expect(response.body).to have_selector(:button, "Check Out for 3 Hours")
        end
      end
      context "when the item is checked out to the user" do
        it "redirects to the viewer" do
          user = FactoryBot.create(:user)
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "123456")
          allow(CDL::EligibleItemService).to receive(:item_ids).and_return(["1"])
          charged_items = [
            CDL::ChargedItem.new(item_id: "1", netid: user.uid, expiration_time: Time.current + 3.hours)
          ]
          FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items)
          sign_in user

          get :auth, params: { id: resource.id.to_s }

          expect(response).to redirect_to viewer_index_path(anchor: "?manifest=http://www.example.com/concern/scanned_resources/#{resource.id}/manifest")
        end
      end
      context "when the item is unavailable and the user has a hold on the item" do
        it "displays a copyright statement and information about their hold" do
          user = FactoryBot.create(:user)
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "123456")
          allow(CDL::EligibleItemService).to receive(:item_ids).and_return(["1"])
          charged_items = [
            CDL::ChargedItem.new(item_id: "1", netid: "other", expiration_time: Time.current + 3.hours)
          ]
          held_items = [
            CDL::Hold.new(skye: "zelda", expiration_time: 1.hour.ago),
            CDL::Hold.new(netid: "zelda"),
            CDL::Hold.new(netid: user.uid)
          ]
          FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items, hold_queue: held_items)
          sign_in user

          get :auth, params: { id: resource.id.to_s }

          expect(response).to be_successful
          expect(response.body).to have_content "This Item may be protected by third-party copyright and/or related intellectual property rights."
          expect(response.body).to have_selector(:button, "Reserve", disabled: true)
          expect(response.body).to have_content(
            "There are 1 reservation(s) ahead of you. We will send you an email notification when your reservation is ready for check out."
          )
        end
      end
      context "when the item is unavailable" do
        it "displays a copyright statement and a hold button" do
          user = FactoryBot.create(:user)
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "123456")
          allow(CDL::EligibleItemService).to receive(:item_ids).and_return(["1"])
          charged_items = [
            CDL::ChargedItem.new(item_id: "1", netid: "other", expiration_time: Time.current + 3.hours)
          ]
          FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items)
          sign_in user

          get :auth, params: { id: resource.id.to_s }

          expect(response).to be_successful
          expect(response.body).to have_content "This Item may be protected by third-party copyright and/or related intellectual property rights."
          expect(response.body).to have_selector(:button, "Reserve")
          expect(response.body).to have_content(
            "This item is currently checked out. However, if you create a reservation we will notify you when it is available for check out" \
            " and hold it for you for up to 1 hour."
          )
          expect(response.body).to have_content "There are currently 0 reservation(s) for this item."
        end
      end
    end
    context "when the user is logged in and the resource is private and CDL ineligible" do
      # This only happens if the user has manually gone to this URL.
      it "redirects back to the viewer" do
        sign_in FactoryBot.create(:user)
        resource = FactoryBot.create_for_repository(:complete_private_scanned_resource)

        get :auth, params: { id: resource.id.to_s }

        expect(response).to redirect_to viewer_index_path(anchor: "?manifest=http://www.example.com/concern/scanned_resources/#{resource.id}/manifest")
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
