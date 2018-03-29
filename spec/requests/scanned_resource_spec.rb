# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe "ScannedResource requests", type: :request do
  with_queue_adapter :inline
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:sample_file) { fixture_file_upload('files/example.tif', 'image/tiff') }
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [sample_file]) }
  let(:file_set) { scanned_resource.member_ids.first }
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/gray.jpg")
      .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
  end

  it 'serves derivatives in the PDF' do
    get "/concern/scanned_resources/#{scanned_resource.id}/pdf"

    reloaded = adapter.query_service.find_by(id: scanned_resource.id)
    expect(response).to redirect_to Valhalla::Engine.routes.url_helpers.download_path(resource_id: scanned_resource.id.to_s, id: reloaded.pdf_file.id.to_s)

    follow_redirect!

    expect(response.status).to eq 200
    expect(response.body).not_to be_empty
    expect(response.content_length).to be > 0
    expect(response.content_type).to eq 'application/pdf'
    expect(response.headers['Content-Disposition']).to eq 'inline; filename="derivative_pdf.pdf"'
  end

  context 'when other derivatives are requested' do
    let(:download_path) { Valhalla::Engine.routes.url_helpers.download_path(resource_id: scanned_resource.id.to_s, id: file_set.id.to_s) }

    it 'redirects the client to be authenticated' do
      get download_path
      expect(response).to redirect_to user_cas_omniauth_authorize_path
    end
  end

  context 'when the resource is privately accessible' do
    let(:scanned_resource) { FactoryBot.create_for_repository(:complete_private_scanned_resource, files: [sample_file]) }

    it 'redirects the client to be authenticated' do
      get "/concern/scanned_resources/#{scanned_resource.id}/pdf"

      reloaded = adapter.query_service.find_by(id: scanned_resource.id)
      expect(response).to redirect_to Valhalla::Engine.routes.url_helpers.download_path(resource_id: scanned_resource.id.to_s, id: reloaded.pdf_file.id.to_s)

      follow_redirect!
      expect(response).to redirect_to user_cas_omniauth_authorize_path
    end
  end
end
