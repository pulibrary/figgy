# frozen_string_literal: true

class GeneratePdfJob < ApplicationJob
  queue_as :realtime

  attr_reader :resource_id
  def perform(resource_id:)
    @resource_id = resource_id
    PDFService.new(change_set_persister).find_or_generate(change_set)
  end

  private

    def change_set
      ChangeSet.for(query_service.find_by(id: resource_id))
    end

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.default
    end

    def query_service
      change_set_persister.query_service
    end
end
