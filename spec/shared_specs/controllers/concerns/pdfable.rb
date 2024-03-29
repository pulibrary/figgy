# frozen_string_literal: true
require "rails_helper"

RSpec.shared_examples "a Pdfable" do
  with_queue_adapter :inline
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource) { FactoryBot.create_for_repository(factory, files: [file], pdf_type: ["gray"]) }
  let(:file_set_id) { resource.member_ids.first }

  before do
    raise "factory must be set with `let(:factory)`" unless defined? factory
    resource
    stub_request(
      :any,
      "http://www.example.com/image-service/#{file_set_id}/full/200,/0/gray.jpg"
    ).to_return(
      body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-landscape-pdf.jpg")),
      status: 200
    )
    sign_in user
  end

  it "generates a pdf, attaches it to the folder, and redirects the user to download it" do
    get :pdf, params: { id: resource.id.to_s }
    reloaded = adapter.query_service.find_by(id: resource.id)
    expect(response).to redirect_to Rails.application.routes.url_helpers.download_path(resource_id: resource.id.to_s, id: reloaded.pdf_file.id.to_s)

    expect(reloaded.file_metadata).not_to be_blank
    expect(reloaded.pdf_file).not_to be_blank
  end
end
