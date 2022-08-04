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
        file_sets.each do |fs|
          mime_type = fs.mime_type&.first
          next unless ControlledVocabulary::GeoRasterFormat.new.include?(mime_type)
          change_set = ChangeSet.for(fs)
          change_set.validate(service_targets: ["tiles"])
          change_set_persister.save(change_set: change_set)
          CreateDerivativesJob.perform_later(fs.id.to_s)
        end
      end
    end

    private

      def change_set_persister
        @change_set_persister ||= ChangeSetPersister.default
      end
  end
end
