
# frozen_string_literal: true
require "rails_helper"

RSpec.describe "ViewerConfiguration requests", type: :request do
  let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource) }

  describe "GET /viewer/config/:id" do
    it "generates a Universal Viewer manifest for the resource" do
      get "/viewer/config/#{scanned_resource.id}", params: { format: :json }

      expect(response.status).to eq 200
      expect(response.body).not_to be_empty
      expect(response.content_length).to be > 0
      expect(response.content_type).to eq "application/json"

      response_values = JSON.parse(response.body)
      expect(response_values).to include "modules"
      expect(response_values["modules"]).to include "pagingHeaderPanel"
      expect(response_values["modules"]).to include "contentLeftPanel"
      expect(response_values["modules"]).to include "footerPanel"
      expect(response_values["modules"]["pagingHeaderPanel"]).to include "options"
      expect(response_values["modules"]["pagingHeaderPanel"]["options"]).to include(
        "autoCompleteBoxEnabled" => false,
        "imageSelectionBoxEnabled" => true
      )
      expect(response_values["modules"]["contentLeftPanel"]).to include "options"
      expect(response_values["modules"]["contentLeftPanel"]["options"]).to include(
        "branchNodesSelectable" => true,
        "defaultToTreeEnabled" => true
      )
      expect(response_values["modules"]["footerPanel"]).to include "options"
      expect(response_values["modules"]["footerPanel"]["options"]).to include(
        "shareEnabled" => true
      )
    end

    context "when the resource does not exist" do
      it "responds with a 404 status code" do
        get "/viewer/config/nonexistent", params: { format: :json }

        expect(response.status).to eq 404
      end
    end

    context "when the resource is not set to be downloadable" do
      let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, downloadable: ["none"]) }

      it "responds with the configuration with downloads disabled" do
        get "/viewer/config/#{scanned_resource.id}", params: { format: :json }

        expect(response.status).to eq 200
        expect(response.body).not_to be_empty
        expect(response.content_length).to be > 0
        expect(response.content_type).to eq "application/json"

        response_values = JSON.parse(response.body)
        expect(response_values).to include "modules"
        expect(response_values["modules"]).to include "footerPanel"
        expect(response_values["modules"]["footerPanel"]).to include "options"
        expect(response_values["modules"]["footerPanel"]["options"]).to include "downloadEnabled" => false
      end

      context "when authenticated as an administrator" do
        let(:admin) { FactoryBot.create(:admin) }

        before do
          sign_in(admin)
        end

        it "responds with the configuration with downloads disabled" do
          get "/viewer/config/#{scanned_resource.id}", params: { format: :json }

          expect(response.status).to eq 200
          expect(response.body).not_to be_empty
          expect(response.content_length).to be > 0
          expect(response.content_type).to eq "application/json"

          response_values = JSON.parse(response.body)
          expect(response_values).to include "modules"
          expect(response_values["modules"]).to include "footerPanel"
          expect(response_values["modules"]["footerPanel"]).to include "options"
          expect(response_values["modules"]["footerPanel"]["options"]).not_to include "downloadEnabled"
        end
      end

      context "when authenticated as a staff member" do
        let(:staff) { FactoryBot.create(:staff) }

        before do
          sign_in(staff)
        end

        it "responds with the configuration with downloads disabled" do
          get "/viewer/config/#{scanned_resource.id}", params: { format: :json }

          expect(response.status).to eq 200
          expect(response.body).not_to be_empty
          expect(response.content_length).to be > 0
          expect(response.content_type).to eq "application/json"

          response_values = JSON.parse(response.body)
          expect(response_values).to include "modules"
          expect(response_values["modules"]).to include "footerPanel"
          expect(response_values["modules"]["footerPanel"]).to include "options"
          expect(response_values["modules"]["footerPanel"]["options"]).not_to include "downloadEnabled"
        end
      end
    end
  end
end
