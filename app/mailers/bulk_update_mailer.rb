# frozen_string_literal: true
class BulkUpdateMailer < ApplicationMailer
  def update_status
    email = params[:email]
    @ids = params[:ids]
    @resource_id = params[:resource_id]
    @time = params[:time]
    @search_params = params[:search_params]
    mail(to: email, subject: "Bulk update status for batch initiated on #{@time}")
  end
end
