# frozen_string_literal: true
class DownloadNotificationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "pdf_download_#{params[:id]}"
  end
end
