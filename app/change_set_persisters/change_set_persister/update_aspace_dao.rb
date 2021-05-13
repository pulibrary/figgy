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
      archival_object = aspace_client.find_archival_object_by_component_id(component_id: change_set.source_metadata_identifier)
      return if archival_object.manifest?(source_metadata_identifier: change_set.source_metadata_identifier)
    end

    def recently_published?
      change_set.changed?(:state) && change_set.resource.decorate.public_readable_state?
    end

    def pulfa_record?
      RemoteRecord.pulfa?(change_set.try(:source_metadata_identifier).to_s)
    end

    def aspace_client
      @aspace_client ||= Aspace::Client.new
    end
  end
end
