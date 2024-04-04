# frozen_string_literal: true
require "rails_helper"

describe GeneratePdfJob do
  describe "#perform" do
    it "broadcasts status messages" do
      file = fixture_file_upload("files/example.tif", "image/tiff")
      file2 = fixture_file_upload("files/example.tif", "image/tiff")
      file3 = fixture_file_upload("files/example.tif", "image/tiff")
      file4 = fixture_file_upload("files/example.tif", "image/tiff")
      file5 = fixture_file_upload("files/example.tif", "image/tiff")
      file6 = fixture_file_upload("files/example.tif", "image/tiff")
      resource = FactoryBot.create_for_repository(:scanned_resource, files: [file, file2, file3, file4, file5, file6])
      stub_request(
        :any,
        /http:\/\/www.example.com\/image-service\/.*\/full\/0,\/0\/gray.jpg/
      ).to_return(
        body: File.open(Rails.root.join("spec", "fixtures", "files", "derivatives", "grey-landscape-pdf.jpg")),
        status: 200
      )

      described_class.perform_now(resource_id: resource.id)
      reloaded = ChangeSetPersister.default.query_service.find_by(id: resource.id)
      expect(broadcasts("pdf_generation_#{resource.id}")).to include({ pctComplete: 1 }.to_json)
      expect(broadcasts("pdf_generation_#{resource.id}")).to include({ pctComplete: 82 }.to_json)
      expect(broadcasts("pdf_generation_#{resource.id}")).to include({ pctComplete: 100, redirectUrl: "/downloads/#{reloaded.id}/file/#{reloaded.pdf_file.id}" }.to_json)
    end
  end
end
