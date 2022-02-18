# frozen_string_literal: true

class ChangeSetPersister
  class ExtractArchivalCollectionCode
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.respond_to?(:source_metadata_identifier)
      return unless change_set.model.respond_to?(:archival_collection_code)
      return unless updated_values?
      return unless RemoteRecord.pulfa?(change_set.source_metadata_identifier)
      change_set.model.archival_collection_code = RemoteRecord.pulfa_collection(change_set.source_metadata_identifier)
      change_set
    end

    private

      # either the source metadata identifier has changed or we're refreshing remote metadata
      def updated_values?
        change_set.changed?(:source_metadata_identifier) || (
          change_set.respond_to?(:apply_remote_metadata?) &&
          change_set.apply_remote_metadata?
        )
      end
  end
end
