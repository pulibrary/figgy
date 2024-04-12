# frozen_string_literal: true

module Migrations
  class ChildResourceCollectionMigrator
    delegate :query_service, to: :change_set_persister

    attr_reader :collection_id, :logger
    def initialize(collection_id:, logger: Rails.logger)
      @collection_id = collection_id
      @logger = logger
    end

    def run
      child_resources = collection.decorate.members.select do |collection_member|
        Wayfinder.for(collection_member).parent.present?
      end
      logger.info "Found #{child_resources.count} child resources as members of collection"
      logger.info "IDs were: #{child_resources.map(&:id)}"
      logger.info "Removing collections from these resources now"

      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        child_resources.each do |child_resource|
          child_change_set = ChangeSet.for(child_resource)
          child_change_set.validate(member_of_collection_ids: [])

          buffered_change_set_persister.save(change_set: child_change_set)
        end
      end
    end

    private

      def change_set_persister
        @change_set_persister ||= ChangeSetPersister.default
      end

      def collection
        @collection ||= query_service.find_by(id: collection_id)
      end
  end
end
