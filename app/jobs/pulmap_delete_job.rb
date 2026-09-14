class PulmapDeleteJob < ApplicationJob
  queue_as :high

  def perform(slug:, commit: true)
    PulmapIndexer.new.delete(slug: slug, commit: commit)
  end
end
