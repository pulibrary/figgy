# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Catalog requests", type: :request do
  with_queue_adapter :inline

  describe "#pdf" do
    context "when the resource was ingested from a pdf" do
      let(:sample_file) { fixture_file_upload("files/sample.pdf", "application/pdf") }
      let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, files: [sample_file]) }

      before do
        stub_catalog(bib_id: "991234563506421")
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
      end

      it "downloads the original pdf" do
        file_set = Wayfinder.for(scanned_resource).source_pdf
        get "/catalog/#{scanned_resource.id}/pdf"
        expect(response).to redirect_to "/downloads/#{file_set.id}/file/#{file_set.file_metadata.first.id}"

        follow_redirect!
        expect(response.status).to be 200
      end

      context "when the resource is private" do
        let(:scanned_resource) { FactoryBot.create_for_repository(:complete_private_scanned_resource, files: [sample_file]) }

        it "redirects the client to be authenticated" do
          file_set = Wayfinder.for(scanned_resource).source_pdf

          get "/catalog/#{scanned_resource.id}/pdf"

          expect(response).to redirect_to "/downloads/#{file_set.id}/file/#{file_set.file_metadata.first.id}"

          follow_redirect!
          expect(response).to redirect_to user_cas_omniauth_authorize_path
        end

        it "can download the original with a token" do
          auth_token = AuthToken.create!(group: ["admin"], label: "Admin Token").token
          file_set = Wayfinder.for(scanned_resource).source_pdf

          get "/catalog/#{scanned_resource.id}/pdf?auth_token=#{auth_token}"

          expect(response).to redirect_to "/downloads/#{file_set.id}/file/#{file_set.file_metadata.first.id}?auth_token=#{auth_token}"

          follow_redirect!
          expect(response.status).to be 200
        end
      end
    end

    context "when the resource can generate a pdf" do
      let(:sample_file) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, files: [sample_file]) }

      before do
        stub_catalog(bib_id: "991234563506421")
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
        # used in pdf generation
        stub_request(:any, "http://www.example.com/image-service/#{scanned_resource.member_ids.first}/full/200,/0/gray.jpg")
          .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
      end

      it "redirects to pdf generation" do
        get "/catalog/#{scanned_resource.id}/pdf"
        expect(response).to redirect_to "/concern/scanned_resources/#{scanned_resource.id}/pdf"
      end

      context "when the resource is private" do
        let(:scanned_resource) { FactoryBot.create_for_repository(:complete_private_scanned_resource, files: [sample_file]) }

        it "redirects the client to be authenticated" do
          get "/catalog/#{scanned_resource.id}/pdf"

          expect(response).to redirect_to "/concern/scanned_resources/#{scanned_resource.id}/pdf"

          follow_redirect! # actually generates the pdf

          adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
          reloaded = adapter.query_service.find_by(id: scanned_resource.id)
          expect(response).to redirect_to "/downloads/#{scanned_resource.id}/file/#{reloaded.pdf_file.id}"

          follow_redirect!
          expect(response).to redirect_to user_cas_omniauth_authorize_path
        end

        it "can download the generated pdf with a token" do
          auth_token = AuthToken.create!(group: ["admin"], label: "Admin Token").token
          get "/catalog/#{scanned_resource.id}/pdf?auth_token=#{auth_token}"

          expect(response.status).to eq 302 # Redirects to the concerns pdf route

          follow_redirect!
          expect(response.status).to eq 302 # This redirects to the downloads controller
          follow_redirect!
          expect(response.status).to eq 200
        end
      end
    end

    context "when the resource can't generate a pdf" do
      let(:resource) { FactoryBot.create_for_repository(:collection) }
      let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }

      it "redirects to the show page" do
        persister.save(resource: resource)
        get "/catalog/#{resource.id}/pdf"
        expect(response).to redirect_to "/catalog/#{resource.id}"
      end
    end
  end
end
