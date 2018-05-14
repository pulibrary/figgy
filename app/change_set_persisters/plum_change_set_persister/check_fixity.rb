# frozen_string_literal: true
class PlumChangeSetPersister
  class CheckFixity
    attr_reader :change_set_persister, :change_set, :post_save_resource

    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      return unless post_save_resource.instance_of? FileSet
      # Don't run if a file has been updated; fixity will run after characterization on the new file
      new_file_scenarios = ["files", "pending_uploads"]
      return unless (change_set.changed.keys & new_file_scenarios).empty?
      ::CheckFixityJob.set(queue: change_set_persister.queue).perform_later(post_save_resource.id.to_s)
    end
  end
end
