# frozen_string_literal: true
require "rails_helper"

RSpec.shared_examples "a Pdfable" do
  include ActiveJob::TestHelper
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

  context "when background_pdf_generating is true" do
    with_queue_adapter :test
    render_views
    it "backgrounds PDF generation and renders a loading page" do
      allow(Figgy).to receive(:background_pdf_generating?).and_return(true)

      get :pdf, params: { id: resource.id.to_s }

      expect(response).to render_template "base/pdf"
      expect(GeneratePdfJob).to have_been_enqueued
      expect(response.body).to have_content resource.title.first.to_s
      expect(response.body).to have_content "0%"
      expect(response.body).to have_selector "img[src='http://www.example.com/image-service/#{resource.member_ids.first}/full/!200,150/0/default.jpg']"
    end
    it "doesn't queue twice if called twice" do
      memory_store = ActiveSupport::Cache.lookup_store(:memory_store)
      allow(Rails).to receive(:cache).and_return(memory_store)
      allow(Figgy).to receive(:background_pdf_generating?).and_return(true)

      get :pdf, params: { id: resource.id.to_s }
      get :pdf, params: { id: resource.id.to_s }

      expect(response).to render_template "base/pdf"
      expect(GeneratePdfJob).to have_been_enqueued.exactly(1).times
    end
    after do
      Rails.cache.clear
      clear_enqueued_jobs
      clear_performed_jobs
    end
  end
end
