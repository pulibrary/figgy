# frozen_string_literal: true
class FixityDashboardController < ApplicationController
  delegate :query_service, to: :metadata_adapter

  def show
    @cloud_failures = query_service.custom_queries.find_cloud_fixity_failures.map(&:decorate).select { |event| event.type == "cloud_fixity" }
    @cloud_recent_checks = query_service.custom_queries.find_cloud_fixity(status: "SUCCESS", sort: "desc", limit: 10).map(&:decorate).select { |event| event.type == "cloud_fixity" }

    @failures = query_service.custom_queries.find_fixity_failures.map(&:decorate)
    @recents = query_service.custom_queries.file_sets_sorted_by_updated(sort: "desc", limit: 10).map(&:decorate)
    @upcoming = query_service.custom_queries.file_sets_sorted_by_updated(limit: 20).map(&:decorate)
    authorize! :read, :fixity
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end
end
