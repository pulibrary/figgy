# frozen_string_literal: true
namespace :pulfalight do
  desc "Sync all pulfalight resources"
  task sync_resources: :environment do
    require 'set'

    @logger = Logger.new(STDOUT)
    @logger.info "Finding resources with archival collection codes"
    query_service = ChangeSetPersister.default.query_service
    resources = query_service.custom_queries.find_by_property(property: :archival_collection_code, value: [], model: ScannedResource, lazy: true)
    refreshed_resources = Set.new
    @logger.info "Resource search complete"
    resources.each do |resource|
      unless refreshed_resources.include?(resource.archival_collection_code)
        RefreshArchivalCollectionJob.perform_later(collection_code: resource.archival_collection_code)
        refreshed_resouces.add(resource.archival_collection_code)
      end
    end
  end
end
