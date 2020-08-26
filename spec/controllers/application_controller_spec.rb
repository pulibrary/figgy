# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController do
  describe "GET /viewer/config/:id" do
    context "when given a CDL resource and not an admin" do
      it "disables share and download" do
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "123456")
        allow(CDL::EligibleItemService).to receive(:item_ids).and_return(["1"])

        get :viewer_config, params: { id: resource.id.to_s, format: :json }

        output = JSON.parse(response.body)
        expect(output["modules"]["footerPanel"]["options"]["downloadEnabled"]).to eq false
        expect(output["modules"]["footerPanel"]["options"]["shareEnabled"]).to eq false
      end
    end
  end
end
