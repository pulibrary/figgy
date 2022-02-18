# frozen_string_literal: true

class ChangeSetPersister
  class CleanupFiles
    attr_reader :resource
    def initialize(change_set:, change_set_persister: nil, post_save_resource: nil)
      @resource = change_set.resource
    end

    def run
      return unless resource.is_a?(FileSet)
      CleanupFilesJob.perform_later(file_identifiers: identifiers_to_remove)
    end

    private

      # Returns the file identifiers for the original file and
      # each derivative attached to a file set.
      def identifiers_to_remove
        resource.file_metadata.flat_map(&:file_identifiers).compact.map(&:to_s)
      end
  end
end
