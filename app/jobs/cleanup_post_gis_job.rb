# frozen_string_literal: true
class CleanupPostGisJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  # @param file_set_id [string] stringified Valkyrie id
  def perform(file_set_id)
    Valkyrie::Derivatives::DerivativeService.for(id: file_set_id)&.cleanup_postgis_table
  end
end
