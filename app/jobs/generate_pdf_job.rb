# frozen_string_literal: true

class GeneratePdfJob < ApplicationJob
  queue_as :realtime

  attr_reader :resource_id
  def perform(resource_id:)
    PDFService.new(change_set_persister).find_or_generate(resource_id: resource_id)
  end

  private

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.default
    end
end
