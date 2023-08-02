# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChangeSetPersister::CleanupTerms do
  with_queue_adapter :inline

  it "cleans up term references from related EphemeraFolders" do
    ephemera_term = FactoryBot.create_for_repository(:ephemera_term)
    resource = FactoryBot.create_for_repository(:ephemera_folder, subject: ephemera_term.id, geographic_origin: ephemera_term.id)
    change_set_persister = ChangeSetPersister.default
    query_service = change_set_persister.query_service
    change_set = ChangeSet.for(ephemera_term)
    change_set_persister.delete(change_set: change_set)
    resource = query_service.find_by(id: resource.id)
    expect(resource.subject).to be_blank
    expect(resource.geographic_origin).to be_blank
  end
end
