# frozen_string_literal: true
namespace :figgy do
  namespace :pulfalight do
    # Time output from running the task on 3/23/23
    # real    2m33.982s
    # user    1m21.634s
    # sys     0m2.178s

    desc "Sync all pulfalight resources"
    task sync_resources: :environment do
      require "set"

      @logger = Logger.new(STDOUT)
      @logger.info "Finding resources with archival collection codes"
      query_service = ChangeSetPersister.default.query_service
      resources = query_service.custom_queries.find_by_property(property: :archival_collection_code, value: [], model: ScannedResource, lazy: true)
      refreshed_resources = Set.new
      @logger.info "Resource search complete"
      resources.each do |resource|
        unless refreshed_resources.include?(resource.archival_collection_code)
          RefreshArchivalCollectionJob.perform_later(collection_code: resource.archival_collection_code)
          refreshed_resources.add(resource.archival_collection_code)
        end
      end
      @logger.info "Size of the set: #{refreshed_resources.size}"
    end
  end
end
