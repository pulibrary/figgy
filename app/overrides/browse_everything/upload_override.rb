# frozen_string_literal: true

module BrowseEverything
  class Upload
    module Override
      def perform_job
      end
    end
  end
end

BrowseEverything::Upload.prepend(BrowseEverything::Upload::Override)
