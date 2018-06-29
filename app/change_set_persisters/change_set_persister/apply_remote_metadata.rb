# frozen_string_literal: true
class ChangeSetPersister
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
      attributes = if change_set.model.media_resource?
                     RemoteRecord.retrieve(change_set.source_metadata_identifier).attributes(title_type: RemoteRecord::PulfaRecord::SIMPLE_TITLE)
                   else
                     RemoteRecord.retrieve(change_set.source_metadata_identifier).attributes
                   end
      apply(attributes)
      change_set
    end

    private

      # Determines whether or not the resource in the ChangeSet is a geospatial resource
      # @return [Boolean]
      def geo_resource?
        change_set.model.respond_to?(:geo_resource?) && change_set.model.geo_resource?
      end

      # Determines whether or not an identifier value is an ARK identifier
      # @param identifier [String]
      # @return [Boolean]
      def ark?(identifier)
        identifier.start_with?(Ark.new(identifier).uri)
      end

      # Determines whether or not an identifier has been modified in the ChangeSet
      # @return [Boolean]
      def identifier_exists?
        change_set.model.identifier.present?
      end

      # Sets the remote metadata for the resource in the ChangeSet
      # @param attributes [Hash]
      def apply(attributes)
        change_set.model.imported_metadata = ImportedMetadata.new(attributes)
        return unless attributes[:identifier] && !geo_resource? && !identifier_exists? && ark?(attributes[:identifier])
        change_set.model.identifier = Ark.new(attributes[:identifier]).identifier
      end
  end
end
