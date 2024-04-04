# frozen_string_literal: true

class GeneratePdfJob < ApplicationJob
  include Rails.application.routes.url_helpers
  queue_as :realtime

  attr_reader :resource_id
  def perform(resource_id:)
    ActionCable.server.broadcast("pdf_generation_#{resource_id}", { pctComplete: 1 })
    PDFService.new(change_set_persister).find_or_generate(resource_id: resource_id)
    resource = change_set_persister.query_service.find_by(id: resource_id)
    ActionCable.server.broadcast("pdf_generation_#{resource_id}", { pctComplete: 100, redirectUrl: download_path(resource, resource.pdf_file) })
  end

  private

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.default
    end
end
