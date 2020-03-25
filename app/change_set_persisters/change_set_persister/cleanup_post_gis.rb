# frozen_string_literal: true
class ChangeSetPersister
  class CleanupPostGis
    attr_reader :resource
    def initialize(change_set_persister: nil, change_set:, post_save_resource: nil)
      @resource = change_set.resource
    end

    def run
      return unless resource.is_a?(FileSet)
      CleanupPostGisJob.perform_later(resource.id.to_s)
    end
  end
end
