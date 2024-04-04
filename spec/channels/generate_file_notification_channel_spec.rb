# frozen_string_literal: true
require "rails_helper"

RSpec.describe GenerateFileNotificationChannel do
  with_queue_adapter :inline
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  it "streams updates about creating a PDF for a resource" do
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])

    expect { subscribe id: resource.id.to_s }.not_to have_broadcasted_to("pdf_generation_#{resource.id}")

    expect(subscription).to have_stream_from("pdf_generation_#{resource.id}")
  end
  it "sends pctComplete: 100 if the pdf is already generated" do
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
    reloaded = ChangeSetPersister.default.query_service.find_by(id: resource.id)
    stub_request(
      :any,
      "http://www.example.com/image-service/#{reloaded.member_ids.first}/full/200,/0/gray.jpg"
    ).to_return(
      body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-landscape-pdf.jpg")),
      status: 200
    )
    GeneratePdfJob.perform_now(resource_id: resource.id.to_s)
    reloaded = ChangeSetPersister.default.query_service.find_by(id: resource.id)

    expect { subscribe id: resource.id.to_s }.to have_broadcasted_to("pdf_generation_#{resource.id}").with(pctComplete: 100, redirectUrl: "/downloads/#{resource.id}/file/#{reloaded.pdf_file.id}")
  end
end
