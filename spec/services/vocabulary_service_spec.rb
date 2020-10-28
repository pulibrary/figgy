# frozen_string_literal: true
require "rails_helper"

RSpec.describe VocabularyService do
  subject(:service) { described_class.new(change_set_persister: change_set_persister,
                                          persist_if_not_found: false) }
  let(:change_set_persister) do
    ChangeSetPersister.new(
      metadata_adapter: adapter,
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { adapter.query_service }

  it "can set persistence on and off" do
    expect(service.persist_if_not_found).to eq(false)
    service.persist_if_not_found = true
    expect(service.persist_if_not_found).to eq(true)
  end

end
