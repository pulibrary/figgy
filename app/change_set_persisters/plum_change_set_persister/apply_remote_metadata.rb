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
      return unless change_set.respond_to?(:source_metadata_identifier)
      return unless change_set.apply_remote_metadata?
      attributes = RemoteRecord.retrieve(change_set.source_metadata_identifier).attributes
      apply(attributes)
      change_set
    end

    private

      def apply(attributes)
        change_set.model.imported_metadata = ImportedMetadata.new(attributes)
        return unless attributes[:identifier] && attributes[:identifier].start_with?('http://arks.princeton.edu/')
        change_set.model.identifier = attributes[:identifier].gsub('http://arks.princeton.edu/', '')
      end
  end
end
