# frozen_string_literal: true
class AddEphemeraToCollectionJob < ApplicationJob
  def perform(project_id, collection_id)
    logger.info "starting job"

    AddEphemeraToCollection.new(project_id: project_id,
                                collection_id: collection_id,
                                logger: logger).add_ephemera

    logger.info "job finished"
  end
end
