# frozen_string_literal: true

module Migrations
  class MapCopyrightMigrator
    def self.call
      new.run
    end

    delegate :query_service, to: :change_set_persister

    def run
      resources.each do |resource|
        next unless resource.rights_statement.include? RightsStatements.no_known_copyright
        change_set = ChangeSet.for(resource)
        change_set.validate(rights_statement: RightsStatements.in_copyright)
        change_set_persister.save(change_set: change_set)
      end
    end

    private

      def models
        [ScannedMap, RasterResource, VectorResource]
      end

      def authenticated_resources
        models.map do |klass|
          query_service.custom_queries.find_by_property(
            property: :visibility,
            value: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
            model: klass
          )
        end
      end

      def private_resources
        models.map do |klass|
          query_service.custom_queries.find_by_property(
            property: :visibility,
            value: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
            model: klass
          )
        end
      end

      def resources
        all_resources = authenticated_resources + private_resources
        all_resources.flatten
      end

      def change_set_persister
        @change_set_persister ||= ChangeSetPersister.default
      end
  end
end
