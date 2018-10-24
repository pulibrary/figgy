# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe "ScannedResource requests", type: :request do
  with_queue_adapter :inline
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:sample_file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, files: [sample_file]) }
  let(:file_set) { scanned_resource.member_ids.first }
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_ezid(shoulder: "99999/fk4", blade: "123456")
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
    expect(response.headers["Content-Disposition"]).to eq 'inline; filename="derivative_pdf.pdf"'
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

  context "when the file metadata for the PDF exists but the file binary cannot be retrieved" do
    let(:missing_pdf_file) do
      FileMetadata.new(
        id: SecureRandom.uuid,
        original_filename: "derivative_pdf.pdf",
        mime_type: "application/pdf",
        use: [Valkyrie::Vocab::PCDMUse.OriginalFile],
        created_at: Time.current,
        updated_at: Time.current
      )
    end
    let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, files: [sample_file], file_metadata: [missing_pdf_file]) }
    before do
      allow(Valkyrie.logger).to receive(:error)
    end
    it "generates a new PDF and logs an error" do
      get "/concern/scanned_resources/#{scanned_resource.id}/pdf"

      reloaded = adapter.query_service.find_by(id: scanned_resource.id)
      expect(reloaded.pdf_file.file_identifiers).not_to include(missing_pdf_file.file_identifiers.first)
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

      reloaded = adapter.query_service.find_by(id: scanned_resource.id)
      expect(response).to redirect_to Rails.application.routes.url_helpers.download_path(resource_id: scanned_resource.id.to_s, id: reloaded.pdf_file.id.to_s)

      follow_redirect!
      expect(response).to redirect_to user_cas_omniauth_authorize_path
    end
  end
end
