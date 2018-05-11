# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PlumChangeSetPersister::PropagateRemoteMetadata do
  subject(:hook) { described_class.new(change_set_persister: change_set_persister, change_set: change_set) }
  let(:query_service) { instance_double(Valkyrie::Persistence::Memory::QueryService) }
  let(:persister) { instance_double(Valkyrie::Persistence::Memory::Persister) }
  let(:change_set_persister) { instance_double(PlumChangeSetPersister::Basic, query_service: query_service) }
  let(:resource) { FactoryBot.build(:archival_media_collection, source_metadata_identifier: 'C0652', identifier: 'http://arks.princeton.edu/ark:/88435/test') }
  let(:change_set) { ArchivalMediaCollectionChangeSet.new(resource, source_metadata_identifier: 'C0652') }
  let(:pulfa_record) { instance_double(RemoteRecord::PulfaRecord) }
  let(:member) { MediaResource.new }

  before do
    allow(persister).to receive(:save)
    allow(change_set_persister).to receive(:persister).and_return(persister)
  end

  describe "#run" do
    context 'when metadata is not being imported' do
      let(:resource) { FactoryBot.build(:archival_media_collection) }
      let(:change_set) { ArchivalMediaCollectionChangeSet.new(resource) }

      before do
        change_set.prepopulate!
        allow(query_service).to receive(:find_inverse_references_by)
        hook.run
      end

      it 'does not request to retrieve the metadata' do
        expect(query_service).not_to have_received(:find_inverse_references_by)
      end
    end

    before do
      allow(pulfa_record).to receive(:attributes).and_return(title: 'test title', identifier: 'http://arks.princeton.edu/ark:/88435/test')
      allow(RemoteRecord).to receive(:retrieve).and_return(pulfa_record)
      allow(query_service).to receive(:find_inverse_references_by).and_return([member])
      hook.run
    end

    it 'requests the metadata' do
      expect(member.title).to include 'test title'
      expect(member.identifier).to include 'ark:/88435/test'
    end
  end
end
