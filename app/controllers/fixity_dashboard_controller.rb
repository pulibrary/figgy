# frozen_string_literal: true
class FixityDashboardController < ApplicationController
  delegate :query_service, to: :metadata_adapter

  def show
    @cloud_failures = query_service.custom_queries.find_fixity_events(status: Event::FAILURE, type: :cloud_fixity).map(&:decorate)
    @cloud_recent_checks = query_service.custom_queries.find_fixity_events(status: Event::SUCCESS, sort: "desc", limit: 10, type: :cloud_fixity).map(&:decorate)

    @failures = query_service.custom_queries.find_fixity_events(status: Event::FAILURE, type: :local_fixity).map(&:decorate)
    @recents = query_service.custom_queries.find_fixity_events(status: Event::SUCCESS, sort: "desc", limit: 10, type: :local_fixity).map(&:decorate)
    authorize! :read, :fixity
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end
end
