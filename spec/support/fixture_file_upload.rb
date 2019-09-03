# frozen_string_literal: true
module FixtureFileUpload
  def fixture_file_upload(file, mime_type)
    Rack::Test::UploadedFile.new(Rails.root.join("spec", "fixtures", file), mime_type)
  end
end
