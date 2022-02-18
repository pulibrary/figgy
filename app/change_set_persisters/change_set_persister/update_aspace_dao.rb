# frozen_string_literal: true

class ChangeSetPersister
  class UpdateAspaceDao
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless pulfa_record?
      return unless recently_published?
      UpdateDaoJob.perform_later(change_set.id.to_s)
    end

    def recently_published?
      change_set.changed?(:state) && change_set.resource.decorate.public_readable_state?
    end

    def pulfa_record?
      RemoteRecord.pulfa?(change_set.try(:source_metadata_identifier).to_s)
    end
  end
end
