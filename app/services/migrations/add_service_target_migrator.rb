# frozen_string_literal: true

module Migrations
  class AddServiceTargetMigrator
    def self.call
      new.run
    end

    delegate :query_service, to: :change_set_persister

    def run
      query_service.find_all_of_model(model: RasterResource).each do |raster_resource|
        file_sets = Wayfinder.for(raster_resource).file_sets
        next unless file_sets.length == 1
        change_set = ChangeSet.for(file_sets[0])
        change_set.validate(service_targets: ["tiles"])
        change_set_persister.save(change_set: change_set)
        CreateDerivativesJob.perform_later(file_sets[0].id.to_s)
      end
    end

    private

      def change_set_persister
        @change_set_persister ||= ChangeSetPersister.default
      end
  end
end
