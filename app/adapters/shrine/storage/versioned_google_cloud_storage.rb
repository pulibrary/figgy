# frozen_string_literal: true

require "shrine/storage/google_cloud_storage"
class Shrine::Storage::VersionedGoogleCloudStorage < Shrine::Storage::GoogleCloudStorage
  def get_file(id)
    get_bucket.files(prefix: id, versions: true, delimiter: "/").sort_by(&:updated_at).last
  end
end
