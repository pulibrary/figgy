# frozen_string_literal: true
class ReportsController < ApplicationController
  def identifiers_to_reconcile
    authorize! :show, Report
    @resources = find_identifiers_to_reconcile_query.find_identifiers_to_reconcile
    respond_to do |format|
      format.html
      format.csv do
        send_data to_csv(@resources, fields: { source_metadata_identifier: 'bibid', identifier: 'ark' }),
                  filename: "identifiers-to-reconcile-#{Time.zone.today}.csv"
      end
    end
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

    def find_identifiers_to_reconcile_query
      FindIdentifiersToReconcile.new(query_service: Valkyrie.config.metadata_adapter.query_service)
    end
end
