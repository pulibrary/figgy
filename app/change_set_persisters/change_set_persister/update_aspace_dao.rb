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
      # Get ASpace archival object ID
      # Get ASpace Archival Object
      # Get digital objects.
    end

    def recently_published?
      change_set.changed?(:state) && change_set.resource.decorate.public_readable_state?
    end

    def pulfa_record?
      RemoteRecord.pulfa?(change_set.try(:source_metadata_identifier).to_s)
    end
  end
end
