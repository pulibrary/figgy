# frozen_string_literal: true
require "rails_helper"

RSpec.describe "ScannedResource requests", type: :request do
  with_queue_adapter :inline
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:sample_file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, files: [sample_file]) }
  let(:file_set) { scanned_resource.member_ids.first }
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_ezid
    stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/gray.jpg")
      .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
  end

  it "serves derivatives in the PDF" do
    get "/concern/scanned_resources/#{scanned_resource.id}/pdf"

    reloaded = adapter.query_service.find_by(id: scanned_resource.id)
    expect(response).to redirect_to Rails.application.routes.url_helpers.download_path(resource_id: scanned_resource.id.to_s, id: reloaded.pdf_file.id.to_s)

    follow_redirect!

    expect(response.status).to eq 200
    expect(response.body).not_to be_empty
    expect(response.content_length).to be > 0
    expect(response.content_type).to eq "application/pdf"
    expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"derivative_pdf.pdf\"; filename*=UTF-8''derivative_pdf.pdf"
  end

  context "when the PDF has already been generated once" do
    before do
      get "/concern/scanned_resources/#{scanned_resource.id}/pdf"
    end
    it "uses the same generated PDF" do
      reloaded = adapter.query_service.find_by(id: scanned_resource.id)

      get "/concern/scanned_resources/#{scanned_resource.id}/pdf"
      twice_reloaded = adapter.query_service.find_by(id: scanned_resource.id)
      expect(twice_reloaded.pdf_file.file_identifiers.first).to eq(reloaded.pdf_file.file_identifiers.first)
    end
  end

  context "when the PDF is generated but an optimistic lock prevents save" do
    it "serves the generated PDF anyway" do
      skip "these don't work; see https://github.com/pulibrary/figgy/issues/2866"
      buffered_csp_mock = instance_double(ChangeSetPersister::Basic)
      allow(buffered_csp_mock).to receive(:save).and_raise(Valkyrie::Persistence::StaleObjectError)
      csp_mock = instance_double(ChangeSetPersister::Basic)
      allow(csp_mock).to receive(:buffer_into_index).and_yield(buffered_csp_mock)
      pdf_service = PDFService.new(csp_mock)
      allow(PDFService).to receive(:new).and_return(pdf_service)
      expect { get "/concern/scanned_resources/#{scanned_resource.id}/pdf" }.not_to raise_error("Valkyrie::Persistence::StaleObjectError")
      expect(response.status).to eq 302
    end
  end

  # Added a more generic check because Read Only Mode might throw an error.
  context "when the PDF is generated but something prevents a save" do
    it "serves the generated PDF anyway" do
      skip "these don't work; see https://github.com/pulibrary/figgy/issues/2866"
      buffered_csp_mock = instance_double(ChangeSetPersister::Basic)
      allow(buffered_csp_mock).to receive(:save).and_raise("something weird happened")
      csp_mock = instance_double(ChangeSetPersister::Basic)
      allow(csp_mock).to receive(:buffer_into_index).and_yield(buffered_csp_mock)
      pdf_service = PDFService.new(csp_mock)
      allow(PDFService).to receive(:new).and_return(pdf_service)
      expect { get "/concern/scanned_resources/#{scanned_resource.id}/pdf" }.not_to raise_error
      expect(response.status).to eq 302
    end
  end

  context "when the file metadata for the PDF exists but the file binary cannot be retrieved" do
    before do
      allow(Valkyrie.logger).to receive(:error)
      get "/concern/scanned_resources/#{scanned_resource.id}/pdf"
    end

    it "generates a new PDF and logs an error" do
      reloaded = adapter.query_service.find_by(id: scanned_resource.id)
      original_pdf_file_identifier = reloaded.pdf_file.file_identifiers.first
      reloaded.pdf_file.file_identifiers = []

      adapter.persister.save(resource: reloaded)

      get "/concern/scanned_resources/#{scanned_resource.id}/pdf"

      reloaded = adapter.query_service.find_by(id: scanned_resource.id)
      expect(reloaded.pdf_file.file_identifiers).not_to be_empty
      expect(reloaded.pdf_file.file_identifiers).not_to include(original_pdf_file_identifier)
      expect(Valkyrie.logger).to have_received(:error).with(/Failed to locate the file for the PDF FileMetadata/)
    end
  end

  context "when other derivatives are requested" do
    let(:download_path) { Rails.application.routes.url_helpers.download_path(resource_id: scanned_resource.id.to_s, id: file_set.id.to_s) }

    it "redirects the client to be authenticated" do
      get download_path
      expect(response).to redirect_to user_cas_omniauth_authorize_path
    end
  end

  context "when the resource is privately accessible" do
    let(:scanned_resource) { FactoryBot.create_for_repository(:complete_private_scanned_resource, files: [sample_file]) }

    it "redirects the client to be authenticated" do
      get "/concern/scanned_resources/#{scanned_resource.id}/pdf"

      # it has to be reloaded to get the pdf_file because hitting this route
      # generates the file
      reloaded = adapter.query_service.find_by(id: scanned_resource.id)
      expect(response).to redirect_to "/downloads/#{scanned_resource.id}/file/#{reloaded.pdf_file.id}"

      follow_redirect!
      expect(response).to redirect_to user_cas_omniauth_authorize_path
    end

    context "when the client passes an authorization token" do
      let(:auth_token) { AuthToken.create!(group: ["admin"], label: "Admin Token").token }

      it "is granted read-only access to the PDF derivatives for the resource" do
        get "/concern/scanned_resources/#{scanned_resource.id}/pdf?auth_token=#{auth_token}"

        expect(response.status).to eq 302 # This redirects to the downloads controller
        follow_redirect!
        expect(response.status).to eq 200
      end

      it "is granted access to the IIIF presentation manifest" do
        get "/concern/scanned_resources/#{scanned_resource.id}/manifest?auth_token=#{auth_token}"

        expect(response.status).to eq 200

        manifest_values = JSON.parse(response.body)
        sequences = manifest_values["sequences"]
        renderings = sequences.first["rendering"]

        expect(renderings.first).to include("@id" => "http://www.example.com/catalog/#{scanned_resource.id}/pdf")

        canvases = sequences.first["canvases"]
        canvas_renderings = canvases.first["rendering"]
        file_set = scanned_resource.decorate.decorated_file_sets.first

        expect(canvas_renderings.first).to include("@id" => "http://www.example.com/downloads/#{file_set.id}/file/#{file_set.original_file.id}")
      end

      it "is granted access to file downloads" do
        file_set = scanned_resource.decorate.decorated_file_sets.first
        get "/downloads/#{file_set.id}/file/#{file_set.original_file.id}?auth_token=#{auth_token}"

        expect(response.status).to eq 200
      end

      context "when the auth. token is nil or invalid" do
        let(:auth_token) { nil }

        it "prevents the client from accessing the catalog show view" do
          get "/catalog/#{scanned_resource.id}?auth_token=#{auth_token}"

          expect(response.status).to eq 302
          expect(response).to redirect_to("/users/auth/cas")
        end

        it "prevents the client from accessing the IIIF manifest for the resource" do
          get "/concern/scanned_resources/#{scanned_resource.id}/manifest?auth_token=#{auth_token}"

          expect(response.status).to eq 403
        end
      end
    end
  end
end
