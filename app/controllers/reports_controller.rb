# frozen_string_literal: true
class ReportsController < ApplicationController
<<<<<<< HEAD
  def ephemera_data
    authorize! :show, Report
    if params[:project_id]
      @ephemera_project = find_resource(params[:project_id]).decorate
      @resources = @ephemera_project.boxes.map(&:folders).flatten
    end
    @ephemera_projects = query_service.find_all_of_model(model: EphemeraProject).map(&:decorate) unless @ephemera_project

    respond_to do |format|
      format.html
      format.csv do
        send_data to_csv(@resources, fields: { id: "id", title: "title", creator: "creator",
                                               contributor: "contributor", publisher: "publisher" }),
                  filename: "#{@ephemera_project.title.parameterize}-data-#{Time.zone.today}.csv"
      end
    end
  end

=======
>>>>>>> d8616123... adds lux order manager to figgy
  def identifiers_to_reconcile
    authorize! :show, Report
    @resources = Valkyrie.config.metadata_adapter.query_service.custom_queries.find_identifiers_to_reconcile
    respond_to do |format|
      format.html
      format.csv do
        send_data to_csv(@resources, fields: { source_metadata_identifier: "bibid", identifier: "ark", title: "title" }),
                  filename: "identifiers-to-reconcile-#{Time.zone.today}.csv"
      end
    end
  end

  private

    def to_csv(records, fields:)
      CSV.generate(headers: true) do |csv|
        csv << fields.map { |_k, v| v }
        records.each do |record|
<<<<<<< HEAD
          csv << fields.map { |k, _v| Array.wrap(record.send(k)).join(";") }
        end
      end
    end

    def find_resource(id)
      query_service.find_by(id: Valkyrie::ID.new(id))
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
=======
          csv << fields.map { |k, _v| Array.wrap(record.send(k)).first }
        end
      end
    end
>>>>>>> d8616123... adds lux order manager to figgy
end
