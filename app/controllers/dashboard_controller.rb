# frozen_string_literal: true
class DashboardController < ApplicationController
  delegate :query_service, to: :metadata_adapter
  def fixity
    @recents = query_service.custom_queries.most_recently_updated_file_sets
    @upcoming = query_service.custom_queries.least_recently_updated_file_sets
    @failures = query_service.custom_queries.find_fixity_failures
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end
end
