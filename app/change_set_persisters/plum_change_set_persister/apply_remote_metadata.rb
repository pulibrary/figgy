# frozen_string_literal: true
class PlumChangeSetPersister
  class ApplyRemoteMetadata
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.respond_to?(:apply_remote_metadata?)
      IdentifierService.mint_or_update(resource: change_set.model) if mint_ark?
      return unless change_set.respond_to?(:source_metadata_identifier)
      return unless change_set.apply_remote_metadata?
      attributes = RemoteRecord.retrieve(change_set.source_metadata_identifier).attributes
      change_set.model.imported_metadata = ImportedMetadata.new(attributes)
      change_set
    end

    def mint_ark?
      return false unless change_set.try(:new_state) == 'complete'
      change_set.try(:state_changed?) || change_set.apply_remote_metadata?
    end
  end
end
