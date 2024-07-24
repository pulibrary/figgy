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
    fields = %w[id local_identifier barcode ephemera_box_number folder_number title sort_title alternative_title
                transliterated_title language ocr_language creator contributor publisher genre
                width height page_count series keywords subject geo_subject geographic_origin
                description date_created rendered_date_range
                provenance source_url dspace_url rights_statement collection_titles]
    respond_to do |format|
      format.html
      format.csv do
        csv_report = CSVReport.new(@resources, fields: fields.index_by(&:to_sym))
        send_data csv_report.to_csv, filename: "#{@ephemera_project.title.parameterize}-data-#{Time.zone.today}.csv"
      end
    end
  end

  def identifiers_to_reconcile
    authorize! :show, Report
    @resources = find_identifiers_to_reconcile
    respond_to do |format|
      format.html
      format.csv do
        csv_report = CSVReport.new(@resources, fields: { source_metadata_identifier: "bibid", identifier: "ark", title: "title" })
        send_data csv_report.to_csv, filename: "identifiers-to-reconcile-#{Time.zone.today}.csv"
      end
    end
  end

  def collection_item_and_image_count
    authorize! :show, Report
    # if the form has been submitted
    if params.key?(:collection_ids) && params.key?(:date_range)
      valid_params = validate_collection_count_params
      if valid_params.present?
        @report = ImageReportGenerator.new(collection_ids: valid_params[:collection_ids], date_range: valid_params[:date_range])
      else
        flash.alert = "There was a problem generating your report. Valid Collection IDs and at least one valid Date are required."
      end
    end
    respond_to do |format|
      format.html
      format.csv do
        send_data @report.to_csv, filename: "collection_item_and_image_count-#{Time.zone.today}.csv"
      end
    end
  end

  def dpul_success_dashboard
    authorize! :show, Report
    # if the form has been submitted
    if params.key?(:date_range)
      valid_params = validate_dpul_date_range
      if valid_params.present?
        @report = DpulSuccessDashboardReportGenerator.new(date_range: valid_params[:date_range])
      else
        flash.alert = "There was a problem generating your report. At least one valid Date is required."
      end
    end
    respond_to do |format|
      format.html
    end
  end

  def pulfa_ark_report
    authorize! :show, Report
    if params[:since_date].present?
      @resources = query_service.custom_queries.updated_archival_resources(since_date: params[:since_date])
    end

    respond_to do |format|
      format.html
      format.csv do
        hashes = @resources.map { |r| resource_hash(r) }
        csv_report = CSVReport.new(hashes, fields: ["id", "component_id", "ark", "url"])
        send_data csv_report.hashes_to_csv, filename: "pulfa-ark-report-#{params[:since_date]}-to-#{Time.zone.today}.csv"
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

    def find_identifiers_to_reconcile
      @identifiers_to_reconcile ||= query_service.custom_queries.find_identifiers_to_reconcile.select do |r|
        PulMetadataServices::Client.catalog?(r.source_metadata_identifier.first)
      end
    end

    def find_resource(id)
      query_service.find_by(id: Valkyrie::ID.new(id))
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    def validate_collection_count_params
      return nil if params[:collection_ids].blank? || params[:date_range].blank? || !valid_dates
      collection_ids = params[:collection_ids].delete(" ").split(",")
      { collection_ids: collection_ids, date_range: valid_dates }
    end

    def validate_dpul_date_range
      return nil if params[:date_range].blank? || !valid_dates
      { date_range: valid_dates }
    end

    def valid_dates
      date_range = params[:date_range].delete(" ").split("-")
      sm, sd, sy = date_range.first.split("/")
      em, ed, ey = date_range.last.split("/")
      return nil unless (Date.valid_date? sy.to_i, sm.to_i, sd.to_i) && (Date.valid_date? ey.to_i, em.to_i, ed.to_i)
      start_date = sy + "-" + sm + "-" + sd
      end_date = ey + "-" + em + "-" + ed
      start_date.to_date..end_date.to_date
    end
end
