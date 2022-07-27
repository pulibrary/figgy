# frozen_string_literal: true

module BrowseEverything
  module UploadOverride
    def perform_job; end
  end
end

BrowseEverything::Upload.prepend(BrowseEverything::UploadOverride)
