# frozen_string_literal: true

module Migrations
  class MapCopyrightMigrator
    def self.call
      new.run
    end

    delegate :query_service, to: :change_set_persister

    def run
      [ScannedMap, RasterResource, VectorResource].each do |klass|
        query_service.custom_queries.find_by_property(
          property: :visibility,
          value: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
          model: klass
        ).each do |resource|
          next unless resource.rights_statement.include? RightsStatements.no_known_copyright
          change_set = ChangeSet.for(resource)
          change_set.validate(rights_statement: RightsStatements.in_copyright)
          change_set_persister.save(change_set: change_set)
        end
      end
    end

    private

      def change_set_persister
        @change_set_persister ||= ChangeSetPersister.default
      end
  end
end
