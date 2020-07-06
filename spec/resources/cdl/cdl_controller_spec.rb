# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cdl::CdlController, type: :controller do
  describe "GET /cdl/:id/status" do
    context "with nobody logged in" do
      it "returns false for everything and no expires_at key" do
        resource = FactoryBot.create_for_repository(:scanned_resource)

        get :status, params: { id: resource.id.to_s }
        json = JSON.parse(response.body)

        expect(json["charged"]).to eq false
        expect(json["available"]).to eq false
      end
    end
    context "with a non-charging user logged in" do
      it "returns the availability" do
        user = FactoryBot.create(:user)
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "123456")
        allow(CDL::EligibleItemService).to receive(:item_ids).and_return(["1"])
        sign_in user

        get :status, params: { id: resource.id.to_s }
        json = JSON.parse(response.body)

        expect(json["charged"]).to eq false
        expect(json["available"]).to eq true
      end
    end
    context "with a charged user logged in" do
      it "returns the availability and expiration" do
        Timecop.freeze do
          user = FactoryBot.create(:user)
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "123456")
          allow(CDL::EligibleItemService).to receive(:item_ids).and_return(["1"])
          charged_items = [
            CDL::ChargedItem.new(item_id: "1", netid: user.uid, expiration_time: Time.current + 3.hours)
          ]
          FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items)
          sign_in user

          get :status, params: { id: resource.id.to_s }
          json = JSON.parse(response.body)

          expect(json["charged"]).to eq true
          expect(json["available"]).to eq false
          expect(json["expires_at"]).to eq((Time.current + 3.hours).to_i)
        end
      end
    end
    context "with an expired charged user logged in" do
      it "returns charged false and available true" do
        Timecop.freeze do
          user = FactoryBot.create(:user)
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "123456")
          allow(CDL::EligibleItemService).to receive(:item_ids).and_return(["1"])
          charged_items = [
            CDL::ChargedItem.new(item_id: "1", netid: user.uid, expiration_time: Time.current - 5.minutes)
          ]
          FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items)
          sign_in user

          get :status, params: { id: resource.id.to_s }
          json = JSON.parse(response.body)

          expect(json["charged"]).to eq false
          expect(json["available"]).to eq true
        end
      end
    end
  end
end
