# frozen_string_literal: true
class Shrine::Storage::GoogleCloudStorage::Versioned < Shrine::Storage::GoogleCloudStorage
  def get_file(id)
    get_bucket.files(prefix: id, versions: true, delimiter: "/").sort_by(&:updated_at).last
  end
end
