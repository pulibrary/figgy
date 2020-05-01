# frozen_string_literal: true

class BrowseEverythingIngestJob < ApplicationJob
  def perform(upload_id:)
    BrowseEverything::UploadJob.perform_now(upload_id: upload_id)
    # Do the stuff in BrowseEverything::UploadJob
    # Then do stuff in BulkIngestController?
  end
end
