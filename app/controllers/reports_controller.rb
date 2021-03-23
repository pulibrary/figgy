# frozen_string_literal: true
require "csv"
class ReportsController < ApplicationController
  def ephemera_data
    authorize! :show, Report
    if params[:project_id]
      @ephemera_project = find_resource(params[:project_id]).decorate
      @resources = @ephemera_project.boxes.map(&:folders).flatten + @ephemera_project.folders
    end
    @ephemera_projects = query_service.find_all_of_model(model: EphemeraProject).map(&:decorate) unless @ephemera_project

    fields = %w[id local_identifier barcode ephemera_box folder_number title sort_title alternative_title
                transliterated_title language ocr_language creator contributor publisher genre
                width height page_count series keywords subject geo_subject geographic_origin
                description date_created rendered_date_range
                provenance source_url dspace_url rights_statement member_of_collections]
    respond_to do |format|
      format.html
      format.csv do
        send_data to_csv(@resources, fields: fields.map { |f| [f.to_sym, f] }.to_h),
                  filename: "#{@ephemera_project.title.parameterize}-data-#{Time.zone.today}.csv"
      end
    end
  end

  def identifiers_to_reconcile
    authorize! :show, Report
    @resources = find_identifiers_to_reconcile
    respond_to do |format|
      format.html
      format.csv do
        send_data to_csv(@resources, fields: { source_metadata_identifier: "bibid", identifier: "ark", title: "title" }),
                  filename: "identifiers-to-reconcile-#{Time.zone.today}.csv"
      end
    end
  end

  def pulfa_ark_report
    authorize! :show, Report
    unless params[:since_date].blank?
      @resources = query_service.custom_queries.updated_archival_resources(since_date: params[:since_date])
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data hashes_to_csv(["id", "component_id", "ark", "url"], @resources.map { |r| resource_hash(r) }),
                  filename: "pulfa-ark-report-#{params[:since_date]}-to-#{Time.zone.today}.csv"
      end
    end
  end

  private

    def resource_hash(resource)
      {
        id: resource.id.to_s,
        component_id: resource.source_metadata_identifier&.first,
        ark: resource.identifier&.first,
        url: helpers.manifest_url(resource)
      }
    end

    def hashes_to_csv(fields, resources)
      CSV.generate(headers: true) do |csv|
        csv << fields
        resources.each do |h|
          csv << fields.map { |field| h[field.to_sym] }
        end
      end
    end

    def find_identifiers_to_reconcile
      @identifiers_to_reconcile ||= query_service.custom_queries.find_identifiers_to_reconcile.select do |r|
        PulMetadataServices::Client.bibdata?(r.source_metadata_identifier.first)
      end
    end

    def to_csv(records, fields:)
      CSV.generate(headers: true) do |csv|
        csv << fields.map { |_k, v| v }
        records.each do |record|
          csv << fields.map { |k, _v| values_or_labels(record, k) }
        end
      end
    end

    def values_or_labels(record, field)
      val = record.send(field)
      Array.wrap(val).map { |v| v.respond_to?(:label) ? v.label : v }.join(";")
    end

    def find_resource(id)
      query_service.find_by(id: Valkyrie::ID.new(id))
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
end
