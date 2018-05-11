# frozen_string_literal: true
class PlumChangeSetPersister
  class PropagateRemoteMetadata
    attr_reader :change_set_persister, :change_set
    delegate :query_service, :persister, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      return unless change_set.respond_to?(:apply_remote_metadata?)
      return unless change_set.respond_to?(:source_metadata_identifier)
      return unless change_set.apply_remote_metadata?
      collection_members.each do |member|
        attributes = RemoteRecord.retrieve(change_set.source_metadata_identifier).attributes
        apply attributes: attributes, resource: member
        change_set
        persister.save(resource: member)
      end
    end

    private

      def collection_members
        query_service.find_inverse_references_by(resource: @post_save_resource, property: :member_of_collection_ids) || []
      end

      def apply(attributes:, resource:)
        resource.imported_metadata = ImportedMetadata.new(attributes)
        return unless attributes[:identifier] && attributes[:identifier].start_with?('http://arks.princeton.edu/')
        resource.identifier = attributes[:identifier].gsub('http://arks.princeton.edu/', '')
      end
  end
end
