# frozen_string_literal: true
require "rails_helper"

RSpec.describe "ExhibitViewerConfiguration requests", type: :request do
  let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource) }

  describe "GET /viewer/exhibit/config" do
    let(:manifest_url) { manifest_scanned_resource_url(scanned_resource) }

    it "generates a Universal Viewer configuration for the exhibit resource" do
      get "/viewer/exhibit/config?manifest=#{CGI.escape(manifest_url)}", params: { format: :json }

      expect(response.status).to eq 200
      expect(response.body).not_to be_empty
      expect(response.content_length).to be > 0
      expect(response.media_type).to eq "application/json"

      response_values = JSON.parse(response.body)
      expect(response_values).to include "modules"
      expect(response_values["modules"]).to include "pagingHeaderPanel"
      expect(response_values["modules"]["pagingHeaderPanel"]).to include "options"
      expect(response_values["modules"]["pagingHeaderPanel"]["options"]).to include(
        "autoCompleteBoxEnabled" => false,
        "imageSelectionBoxEnabled" => true
      )
    end

    context "with a request for hypertext content" do
      it "generates a Universal Viewer configuration for the exhibit resource" do
        get "/viewer/exhibit/config?manifest=#{CGI.escape(manifest_url)}", params: { format: :html }

        expect(response.status).to eq 200
        expect(response.body).not_to be_empty
        expect(response.content_length).to be > 0
        expect(response.media_type).to eq "text/html"

        response_values = JSON.parse(response.body)
        expect(response_values).to include "modules"
        expect(response_values["modules"]).to include "pagingHeaderPanel"
        expect(response_values["modules"]["pagingHeaderPanel"]).to include "options"
        expect(response_values["modules"]["pagingHeaderPanel"]["options"]).to include(
          "autoCompleteBoxEnabled" => false,
          "imageSelectionBoxEnabled" => true
        )
      end
    end

    context "without a manifest parameter" do
      it "responds with a 400 status code" do
        get "/viewer/exhibit/config", params: { format: :json }

        expect(response.status).to eq 400
      end
    end

    context "when the resource is not set to be downloadable" do
      let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, downloadable: ["none"]) }

      it "responds with the configuration with downloads disabled" do
        get "/viewer/exhibit/config?manifest=#{CGI.escape(manifest_url)}", params: { format: :json }

        expect(response.status).to eq 200
        expect(response.body).not_to be_empty
        expect(response.content_length).to be > 0
        expect(response.media_type).to eq "application/json"

        response_values = JSON.parse(response.body)
        expect(response_values).to include "modules"
        expect(response_values["modules"]).to include "footerPanel"
        expect(response_values["modules"]["footerPanel"]).to include "options"
        expect(response_values["modules"]["footerPanel"]["options"]).to include "downloadEnabled" => false
      end
    end
  end
end
