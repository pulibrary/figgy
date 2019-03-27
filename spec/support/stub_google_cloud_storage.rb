# frozen_string_literal: true
module GoogleCloudStorageStubbing
  def stub_google_cloud_resource(id:, md5_hash:, crc32c:, local_file_path:)
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
    stub_request(:get, "https://www.googleapis.com/storage/v1/b/project-figgy-bucket/o/#{id}").to_return(
      status: 404,
      body: JSON.generate(
        "error": {
          "errors": [
            {
              "domain": "global",
              "reason": "notFound",
              "message": "No such object: project-figgy-bucket/#{id}/example.tif"
            }
          ],
          "code": 404,
          "message": "No such object: project-figgy-bucket/#{id}/example.tif"
        }
      ),
      headers: {
        "Content-Type" => "application/json; charset=utf-8"
      }
    )
    stub_request(:post, "https://www.googleapis.com/upload/storage/v1/b/project-figgy-bucket/o?name=#{id}").to_return(
      status: 200,
      headers: {
        "X-Guploader-Uploadid" => "AEnB2UqYKLowO6rkE3VBx-yntKGQHfUTSHzag-pK83Kqot1Ge_E85AJvX-GE6EDo8_x-QhyZ85bMmx2Xc_dAO-vL7WC9-69aIA",
        "X-Goog-Upload-Status" => "active",
        "X-Goog-Upload-Url" => "https://www.googleapis.com/upload/storage/v1/b/project-figgy-bucket/o?name=#{id}&upload_id=AEnB2UqYKLowO6rkE3VBx-yntKGQHfUTSHzag-pK83Kqot1Ge_E85AJvX-GE6EDo8_x-QhyZ85bMmx2Xc_dAO-vL7WC9-69aIA&upload_protocol=resumable",
        "X-Goog-Upload-Control-Url" => "https://www.googleapis.com/upload/storage/v1/b/project-figgy-bucket/o?name=#{id}&upload_id=AEnB2UqYKLowO6rkE3VBx-yntKGQHfUTSHzag-pK83Kqot1Ge_E85AJvX-GE6EDo8_x-QhyZ85bMmx2Xc_dAO-vL7WC9-69aIA&upload_protocol=resumable",
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
    stub_request(:post, "https://www.googleapis.com/upload/storage/v1/b/project-figgy-bucket/o?name=#{id}&upload_id=AEnB2UqYKLowO6rkE3VBx-yntKGQHfUTSHzag-pK83Kqot1Ge_E85AJvX-GE6EDo8_x-QhyZ85bMmx2Xc_dAO-vL7WC9-69aIA&upload_protocol=resumable").to_return(
      status: 200,
      body: JSON.generate(
        "kind": "storage#object",
        "id": "project-figgy-bucket/#{id}/1553626388194725",
        "selfLink": "https://www.googleapis.com/storage/v1/b/project-figgy-bucket/o/#{id}",
        "name": id.to_s,
        "bucket": "project-figgy-bucket",
        "generation": "1553626388194725",
        "metageneration": "1",
        "contentType": "application/octet-stream",
        "timeCreated": "2019-03-26T18:53:08.194Z",
        "updated": "2019-03-26T18:53:08.194Z",
        "storageClass": "STANDARD",
        "timeStorageClassUpdated": "2019-03-26T18:53:08.194Z",
        "size": "196882",
        "md5Hash": md5_hash,
        "mediaLink": "https://www.googleapis.com/download/storage/v1/b/project-figgy-bucket/o/#{id}?generation=1553626388194725&alt=media",
        "crc32c": crc32c,
        "etag": "CKXL7ae9oOECEAE="
      ),
      headers: {
        "Content-Type" => "application/json; charset=utf-8",
        "X-Guploader-Uploadid" => "AEnB2UqYKLowO6rkE3VBx-yntKGQHfUTSHzag-pK83Kqot1Ge_E85AJvX-GE6EDo8_x-QhyZ85bMmx2Xc_dAO-vL7WC9-69aIA",
        "X-Goog-Upload-Status" => "final",
        "Etag" => "CKXL7ae9oOECEAE="
      }
    )
    stub_request(:get, "https://www.googleapis.com/storage/v1/b/project-figgy-bucket/o/#{id}?alt=media").to_return(
      status: 200,
      body: File.read(local_file_path),
      headers: {
        "Content-Type" => "application/octet-stream"
      }
    )
  end
end

RSpec.configure do |config|
  config.include GoogleCloudStorageStubbing
end
