# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FindIdentifiersToReconcile do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:resource) { FactoryBot.build(:scanned_resource, title: []) }
  let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, title: []) }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }

  before do
    stub_bibdata(bib_id: '123456')
    stub_ezid(shoulder: "99999/fk4", blade: "8675309")
  end

  describe "#find_identifiers_to_reconcile" do
    it "finds only resources with newly-minted identifiers" do
      change_set = ScannedResourceChangeSet.new(resource)
      change_set.validate(source_metadata_identifier: '123456')
      change_set.sync
      saved_resource = change_set_persister.save(change_set: change_set)

      output = query.find_identifiers_to_reconcile
      ids = output.map(&:id)
      expect(ids).to include saved_resource.id
      expect(ids).not_to include resource2.id
    end
  end
end
