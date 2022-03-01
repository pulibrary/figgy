# frozen_string_literal: true
class ChangeSetPersister
  class ClearRemoteMetadata
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.respond_to?(:source_metadata_identifier)
      return if change_set.model.try(:imported_metadata).blank?
      return if change_set.source_metadata_identifier.present?
      change_set.model.imported_metadata = []
      change_set
    end
  end
end
