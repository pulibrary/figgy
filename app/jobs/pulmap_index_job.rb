class PulmapIndexJob < ApplicationJob
  queue_as :low

  def perform(document:, commit: true)
    PulmapIndexer.new.index(document: document, commit: commit)
  end
end
