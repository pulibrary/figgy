# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FindUnrelated do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:query_service) { metadata_adapter.query_service }

  let(:resource1) do
    sr = FactoryBot.create_for_repository(:scanned_resource)
    change_set = ScannedResourceChangeSet.new(sr)
    change_set.prepopulate!
    change_set_persister.save(change_set: change_set)
  end
  let(:resource2) do
    sr = FactoryBot.create_for_repository(:scanned_resource)
    change_set = ScannedResourceChangeSet.new(sr)
    change_set.prepopulate!
    change_set_persister.save(change_set: change_set)
  end
  let(:resource3) do
    sr = FactoryBot.create_for_repository(:scanned_resource, member_ids: [resource2.id])
    change_set = ScannedResourceChangeSet.new(sr)
    change_set.prepopulate!
    change_set_persister.save(change_set: change_set)
  end
  let(:resource4) do
    sr = FactoryBot.create_for_repository(:scanned_resource, member_ids: [resource1.id])
    change_set = ScannedResourceChangeSet.new(sr)
    change_set.prepopulate!
    change_set_persister.save(change_set: change_set)
  end

  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }

  before do
    stub_ezid(shoulder: "99999/fk4", blade: "8675309")
  end

  describe "#find_unrelated" do
    let(:connection) { Blacklight.default_index.connection }
    before do
      resource1
      resource2
      resource3
      resource4
    end
    it 'only finds resources unrelated by membership to a given resource' do
      output = query.find_unrelated(resource: resource3, model: resource3.class)
      ids = output.map(&:id)
      expect(ids).to include resource1.id
      expect(ids).to include resource4.id
      expect(ids).not_to include resource2.id
      expect(ids).not_to include resource3.id
    end
  end
end
