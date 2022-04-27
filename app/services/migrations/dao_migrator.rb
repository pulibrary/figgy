# frozen_string_literal: true

module Migrations
  class DaoMigrator
    def self.call
      new.run
    end

    delegate :query_service, to: :change_set_persister

    def run
      ids = query_service.custom_queries.find_ids_with_property_not_empty(property: :archival_collection_code)
      ids.map(&:to_s).each { |id| UpdateDaoJob.perform_later(id) }
    end

    private

      def change_set_persister
        @change_set_persister ||= ChangeSetPersister.default
      end
  end
end
