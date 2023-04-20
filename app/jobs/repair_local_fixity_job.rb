# frozen_string_literal: true

# Replaces files with the preservation copy from Google Cloud.
class RepairLocalFixityJob < ApplicationJob
  def perform(file_set_id)
    file_set = query_service.find_by(id: file_set_id)
    RepairLocalFixity.run(file_set)
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
