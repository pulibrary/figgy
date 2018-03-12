# frozen_string_literal: true
class DashboardController < ApplicationController
  delegate :query_service, to: :metadata_adapter
  def fixity
    @failures = query_service.custom_queries.find_fixity_failures
    @recents = query_service.custom_queries.file_sets_sorted_by_updated(sort: 'desc', limit: 10)
    @upcoming = query_service.custom_queries.file_sets_sorted_by_updated(limit: 20)
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end
end
