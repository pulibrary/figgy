# frozen_string_literal: true
require "rails_helper"

RSpec.shared_examples "a Pdfable" do
  with_queue_adapter :inline
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }

  before do
    raise "resource must be set with `let(:resource)`" unless
      defined? resource
    sign_in user
  end

  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:pdf_file) do
    file = fixture_file_upload("files/example.tif", "application/pdf")
    node = FileMetadata.for(file: file).new(id: SecureRandom.uuid)
    stored_file = storage_adapter.upload(resource: node, file: file, original_filename: "tmp.pdf")
    node.file_identifiers = stored_file.id
    node
  end
  let(:pdf_generator) { double }

  before do
    allow(PDFGenerator).to receive(:new).and_return(pdf_generator)
    allow(pdf_generator).to receive(:render).and_return(pdf_file)
  end

  it "generates a pdf, attaches it to the folder, and redirects the user to download it" do
    get :pdf, params: { id: resource.id.to_s }
    reloaded = adapter.query_service.find_by(id: resource.id)
    expect(response).to redirect_to Rails.application.routes.url_helpers.download_path(resource_id: resource.id.to_s, id: reloaded.pdf_file.id.to_s)

    expect(reloaded.file_metadata).not_to be_blank
    expect(reloaded.pdf_file).not_to be_blank
  end
end
