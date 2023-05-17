# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindIdentifiersToReconcile do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:complete_resource) { FactoryBot.build(:complete_scanned_resource, title: []) }
  let(:basic_resource) { FactoryBot.create_for_repository(:scanned_resource, title: []) }
  let(:incomplete_resource) { FactoryBot.create_for_repository(:scanned_resource, title: []) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }

  before do
    stub_catalog(bib_id: "991234563506421")
    stub_ezid
  end

  describe "#find_identifiers_to_reconcile" do
    it "finds only resources with newly-minted identifiers" do
      # add remote metadata to a complete resource, which should be retrieved because its ARK won't be
      # present in the remote metadata
      change_set = ScannedResourceChangeSet.new(complete_resource)
      change_set.validate(source_metadata_identifier: "991234563506421")
      saved_resource = change_set_persister.save(change_set: change_set)

      # add remote metadata to an incomplete resource, which should not be retrieved because it won't have
      # an ARK minted yet
      change_set = ScannedResourceChangeSet.new(incomplete_resource)
      change_set.validate(source_metadata_identifier: "991234563506421")
      change_set_persister.save(change_set: change_set)

      output = query.find_identifiers_to_reconcile
      ids = output.map(&:id)
      expect(ids).to include saved_resource.id
      expect(ids).not_to include basic_resource.id
      expect(ids).not_to include incomplete_resource.id
    end
  end
end
