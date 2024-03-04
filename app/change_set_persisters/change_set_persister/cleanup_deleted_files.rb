# frozen_string_literal: true
class ChangeSetPersister
  class CleanupDeletedFiles
    attr_reader :change_set
    def initialize(change_set_persister: nil, change_set:, post_save_resource: nil)
      @change_set = change_set
    end

    def run
      return unless change_set.resource.is_a?(FileSet) && change_set.deleted_file_identifiers.present?
      CleanupFilesJob.perform_later(file_identifiers: change_set.deleted_file_identifiers.map(&:to_s))
    end
  end
end
