# frozen_string_literal: true

class CleanDeletedSubjectJob < ApplicationJob
  def perform(subject_id, logger: Logger.new($stdout))
    adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
    qs = adapter.query_service
    folders = qs.find_inverse_references_by(property: :subject, id: subject_id)
    csp = ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
    folders.each do |folder|
      cs = ChangeSet.for(folder)
      subjects = cs.subject.reject { |id| id.to_s == subject_id }
      cs.validate(subject: subjects)
      if cs.valid?
        csp.save(change_set: cs)
      else
        logger.warn("change set did not validate for #{folder.id}")
      end
    end
  end
end
