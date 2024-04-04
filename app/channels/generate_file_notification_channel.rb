# frozen_string_literal: true
class GenerateFileNotificationChannel < ApplicationCable::Channel
  include Rails.application.routes.url_helpers
  after_subscribe :send_initial_status
  def subscribed
    stream_from "pdf_generation_#{params[:id]}"
  end

  def send_initial_status
    resource = ChangeSetPersister.default.query_service.find_by(id: params[:id])
    return if resource.try(:pdf_file).blank?
    ActionCable.server.broadcast("pdf_generation_#{params[:id]}", { pctComplete: 100, redirectUrl: download_path(resource, resource.pdf_file) })
  end
end
