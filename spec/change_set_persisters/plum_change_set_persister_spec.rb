# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe PlumChangeSetPersister do
  subject(:change_set_persister) do
    described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_class) { ScannedResourceChangeSet }
  it_behaves_like "a Valkyrie::ChangeSetPersister"
end
