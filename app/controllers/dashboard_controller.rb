# frozen_string_literal: true
class DashboardController < ApplicationController
  delegate :query_service, to: :metadata_adapter

  def identifiers_to_reconcile
    authorize! :show, Report
    @resources = Valkyrie.config.metadata_adapter.query_service.custom_queries.find_identifiers_to_reconcile
    respond_to do |format|
      format.html
      format.csv do
        send_data to_csv(@resources, fields: { source_metadata_identifier: 'bibid', identifier: 'ark', title: 'title' }),
                  filename: "identifiers-to-reconcile-#{Time.zone.today}.csv"
      end
    end
  end

  def fixity
    @failures = query_service.custom_queries.find_fixity_failures
    @recents = query_service.custom_queries.file_sets_sorted_by_updated(sort: 'desc', limit: 10)
    @upcoming = query_service.custom_queries.file_sets_sorted_by_updated(limit: 20)
  end

  private

    def to_csv(records, fields:)
      CSV.generate(headers: true) do |csv|
        csv << fields.map { |_k, v| v }
        records.each do |record|
          csv << fields.map { |k, _v| Array.wrap(record.send(k)).first }
        end
      end
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
