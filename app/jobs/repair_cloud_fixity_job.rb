# frozen_string_literal: true
class RepairCloudFixityJob < ApplicationJob
  def perform(event_id:)
    event = query_service.find_by(id: event_id)
    RepairCloudFixity.run(event: event)
  end

  private

    def query_service
      ChangeSetPersister.default.query_service
    end
end
