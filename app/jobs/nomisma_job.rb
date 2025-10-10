# frozen_string_literal: true

class NomismaJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(nomisma_document_id)
    record = NomismaDocument.find(nomisma_document_id)
    record.update(state: "processing")
    rdf = Nomisma.generate
    record.update(state: "complete", rdf: rdf)
  end
end
