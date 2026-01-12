# frozen_string_literal: true
class HealthReportsController < ApplicationController
  def check
    authorize! :show, Report
    respond_to do |format|
      format.json do
        render json: HealthReport.for(resource).to_h.to_json
      end
    end
  end

  private

    def resource
      @resource ||= query_service.find_by(id: Valkyrie::ID.new(params[:id]))
    end
end
