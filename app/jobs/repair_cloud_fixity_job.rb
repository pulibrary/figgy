# frozen_string_literal: true
class RepairCloudFixityJob < ApplicationJob
  def perform(event:)
    RepairCloudFixity.run(event: event)
  end
end
