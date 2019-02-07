# frozen_string_literal: true
class ChangeSetPersister
  class CheckFixity
    attr_reader :change_set_persister, :change_set

    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
      # @post_save_resource = post_save_resource
    end

    def run
      return unless change_set.resource.instance_of? FileSet
      # Don't run if a file has been updated; fixity will run after characterization on the new file
      new_file_scenarios = ["files", "pending_uploads"]
      return unless (change_set.changed.keys & new_file_scenarios).empty?
      ::CheckFixityJob.perform_later(change_set.resource.id.to_s)
    end
  end
end
