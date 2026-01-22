class PreservationAuditsController < ApplicationController
  before_action :set_preservation_audit, only: %i[show]

  # GET /preservation_audits or /preservation_audits.json
  def index
    authorize! :read, :fixity
    @preservation_audits = PreservationAudit.order(created_at: :desc)
  end

  # GET /preservation_audits/1 or /preservation_audits/1.json
  def show
    authorize! :read, :fixity
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_preservation_audit
      @preservation_audit = PreservationAudit.find(params[:id])
    end
end
