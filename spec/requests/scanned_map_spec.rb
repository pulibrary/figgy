# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ScannedMap requests", type: :request do
  with_queue_adapter :inline
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:sample_file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:scanned_map) { FactoryBot.create_for_repository(:complete_scanned_map, files: [sample_file]) }
  let(:file_set) { scanned_map.member_ids.first }
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_ezid(shoulder: "99999/fk4", blade: "123456")
    stub_request(:any, "http://www.example.com/image-service/#{file_set.id}/full/200,/0/gray.jpg")
      .to_return(body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-pdf.jpg")), status: 200)
  end

  it "serves derivatives in the PDF" do
    get "/concern/scanned_maps/#{scanned_map.id}/pdf"

    reloaded = adapter.query_service.find_by(id: scanned_map.id)
    expect(response).to redirect_to Rails.application.routes.url_helpers.download_path(resource_id: scanned_map.id.to_s, id: reloaded.pdf_file.id.to_s)

    follow_redirect!

    expect(response.status).to eq 200
    expect(response.body).not_to be_empty
    expect(response.content_length).to be > 0
    expect(response.content_type).to eq "application/pdf"
    expect(response.headers["Content-Disposition"]).to eq 'inline; filename="derivative_pdf.pdf"'
  end
end
