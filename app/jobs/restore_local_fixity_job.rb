# frozen_string_literal: true

# Replaces files with the preservation copy from Google Cloud.
class RestoreLocalFixityJob < ApplicationJob
  def perform(file_set_id)
    file_set = query_service.find_by(id: file_set_id)
    RestoreLocalFixity.run(file_set)
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
