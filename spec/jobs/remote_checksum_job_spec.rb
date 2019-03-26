# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe RemoteChecksumJob do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  let(:file_set) { scanned_resource.decorate.file_sets.first }

  before do
    stub_request(:get, "http://169.254.169.254/").to_return(
      status: 200, body: "", headers: {}
    )
    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token").to_return(
      status: 200,
      body: JSON.generate(
        "access_token": "ya29.c.ElnYBp7Es0M2VpXr2fJIz5oAYCNvxkapBXu0MRom2ceZA0e_1FIXc45IjrqRBsGYMYQUSm8Yp7SNqdFMCHCVdNGktpYW8Vx2K3C2Oo2E8mlkAS1DzLC8bDAW2g",
        "expires_in": 3600,
        "token_type": "Bearer"
      ),
      headers: {
        "Content-Type" => "application/json; charset=utf-8"
      }
    )
    stub_request(:post, "https://oauth2.googleapis.com/token").to_return(
      status: 200,
      body: JSON.generate(
        "access_token": "ya29.c.ElnYBp7Es0M2VpXr2fJIz5oAYCNvxkapBXu0MRom2ceZA0e_1FIXc45IjrqRBsGYMYQUSm8Yp7SNqdFMCHCVdNGktpYW8Vx2K3C2Oo2E8mlkAS1DzLC8bDAW2g",
        "expires_in": 3600,
        "token_type": "Bearer"
      ),
      headers: {
        "Content-Type" => "application/json; charset=utf-8"
      }
    )
    stub_request(:get, "https://www.googleapis.com/storage/v1/b/project-figgy-bucket").to_return(
      status: 200,
      body: JSON.generate(
        "kind": "storage#bucket",
        "id": "project-figgy-bucket",
        "selfLink": "https://www.googleapis.com/storage/v1/b/project-figgy-bucket",
        "projectNumber": "2696948707",
        "name": "project-figgy-bucket",
        "timeCreated": "2019-03-26T15:40:54.940Z",
        "updated": "2019-03-26T15:40:54.940Z",
        "metageneration": "1",
        "iamConfiguration": {
          "bucketPolicyOnly": {
            "enabled": false
          }
        },
        "location": "US",
        "storageClass": "STANDARD",
        "etag": "CAE="
      ),
      headers: {
        "Content-Type" => "application/json; charset=utf-8"
      }
    )
    stub_request(:get, "https://www.googleapis.com/storage/v1/b/project-figgy-bucket/o/#{file_set.original_file.id}").to_return(
      status: 404,
      body: JSON.generate(
        "error": {
          "errors": [
            {
              "domain": "global",
              "reason": "notFound",
              "message": "No such object: project-figgy-bucket/e540688ad28748ecb033dc27813459c6/example.tif"
            }
          ],
          "code": 404,
          "message": "No such object: project-figgy-bucket/e540688ad28748ecb033dc27813459c6/example.tif"
        }
      ),
      headers: {
        "Content-Type" => "application/json; charset=utf-8"
      }
    )
    stub_request(:post, "https://www.googleapis.com/upload/storage/v1/b/project-figgy-bucket/o?name=#{file_set.original_file.id}").to_return(
      status: 200,
      headers: {
        "X-Guploader-Uploadid" => "AEnB2UqYKLowO6rkE3VBx-yntKGQHfUTSHzag-pK83Kqot1Ge_E85AJvX-GE6EDo8_x-QhyZ85bMmx2Xc_dAO-vL7WC9-69aIA",
        "X-Goog-Upload-Status" => "active",
        "X-Goog-Upload-Url" => "https://www.googleapis.com/upload/storage/v1/b/project-figgy-bucket/o?name=e540688a-d287-48ec-b033-dc27813459c6&upload_id=AEnB2UqYKLowO6rkE3VBx-yntKGQHfUTSHzag-pK83Kqot1Ge_E85AJvX-GE6EDo8_x-QhyZ85bMmx2Xc_dAO-vL7WC9-69aIA&upload_protocol=resumable",
        "X-Goog-Upload-Control-Url" => "https://www.googleapis.com/upload/storage/v1/b/project-figgy-bucket/o?name=e540688a-d287-48ec-b033-dc27813459c6&upload_id=AEnB2UqYKLowO6rkE3VBx-yntKGQHfUTSHzag-pK83Kqot1Ge_E85AJvX-GE6EDo8_x-QhyZ85bMmx2Xc_dAO-vL7WC9-69aIA&upload_protocol=resumable",
        "X-Goog-Upload-Chunk-Granularity" => "262144",
        "X-Goog-Upload-Header-Vary" => ["Origin", "X-Origin"],
        "X-Goog-Upload-Header-X-Google-Backends" => "xhiadbar8:4152",
        "X-Goog-Upload-Header-X-Google-Session-Info" => "CMOGgvqHDxoCGAYoATpEChJjbG91ZC1zdG9yYWdlLXJvc3kSCGJpZ3N0b3JlGOPXgIYKIhUxMDIxMzU0MzE3NjY3ODg5MTUwMTkw4Csw4Ssw4ytKGDoWTk9UX0FfUEVSU0lTVEVOVF9UT0tFTg",
        "X-Goog-Upload-Header-Cache-Control" => "no-cache, no-store, max-age=0, must-revalidate",
        "X-Goog-Upload-Header-Pragma" => "no-cache",
        "X-Goog-Upload-Header-Expires" => "Mon, 01 Jan 1990 00:00:00 GMT",
        "X-Goog-Upload-Header-Date" => "Tue, 26 Mar 2019 18:53:07 GMT"
      }
    )
    stub_request(:post, "https://www.googleapis.com/upload/storage/v1/b/project-figgy-bucket/o?name=e540688a-d287-48ec-b033-dc27813459c6&upload_id=AEnB2UqYKLowO6rkE3VBx-yntKGQHfUTSHzag-pK83Kqot1Ge_E85AJvX-GE6EDo8_x-QhyZ85bMmx2Xc_dAO-vL7WC9-69aIA&upload_protocol=resumable").to_return(
      status: 200,
      body: JSON.generate(
        "kind": "storage#object",
        "id": "project-figgy-bucket/e540688a-d287-48ec-b033-dc27813459c6/1553626388194725",
        "selfLink": "https://www.googleapis.com/storage/v1/b/project-figgy-bucket/o/e540688a-d287-48ec-b033-dc27813459c6",
        "name": "e540688a-d287-48ec-b033-dc27813459c6",
        "bucket": "project-figgy-bucket",
        "generation": "1553626388194725",
        "metageneration": "1",
        "contentType": "application/octet-stream",
        "timeCreated": "2019-03-26T18:53:08.194Z",
        "updated": "2019-03-26T18:53:08.194Z",
        "storageClass": "STANDARD",
        "timeStorageClassUpdated": "2019-03-26T18:53:08.194Z",
        "size": "196882",
        "md5Hash": "Kij7cCKGeCssvy7ZpQQasQ==",
        "mediaLink": "https://www.googleapis.com/download/storage/v1/b/project-figgy-bucket/o/e540688a-d287-48ec-b033-dc27813459c6?generation=1553626388194725&alt=media",
        "crc32c": "VWK9WA==",
        "etag": "CKXL7ae9oOECEAE="
      ),
      headers: {
        "Content-Type" => "application/json; charset=utf-8",
        "X-Guploader-Uploadid" => "AEnB2UqYKLowO6rkE3VBx-yntKGQHfUTSHzag-pK83Kqot1Ge_E85AJvX-GE6EDo8_x-QhyZ85bMmx2Xc_dAO-vL7WC9-69aIA",
        "X-Goog-Upload-Status" => "final",
        "Etag" => "CKXL7ae9oOECEAE="
      }
    )
  end

  describe ".perform_now" do
    before do
      Figgy.config["google_cloud_storage"]["credentials"]["private_key"] = OpenSSL::PKey::RSA.new(2048).to_s
    end

    it "triggers a derivatives_created message", rabbit_stubbed: true do
      described_class.perform_now(file_set.id.to_s)
      reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: file_set.id)

      expect(reloaded.remote_checksum).to eq ["Kij7cCKGeCssvy7ZpQQasQ=="]
    end
  end
end
