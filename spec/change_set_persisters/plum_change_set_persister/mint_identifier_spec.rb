# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PlumChangeSetPersister::MintIdentifier do
  subject(:hook) { described_class.new(change_set_persister: change_set_persister, change_set: change_set) }
  let(:change_set_persister) { instance_double(PlumChangeSetPersister::Basic, query_service: query_service) }
  let(:change_set) { SimpleResourceChangeSet.new(simple_resource) }
  let(:simple_resource) { FactoryBot.create(:published_simple_resource) }
  let(:query_service) { instance_double(Valkyrie::Persistence::Memory::QueryService) }

  describe "#run" do
    let(:identifier_service) { class_double(IdentifierService).as_stubbed_const transfer_nested_constants: true }
    let(:shoulder) { '99999/fk4' }
    let(:blade) { '123456' }
    let(:new_ark) { "ark:/#{shoulder}#{blade}" }

    before do
      stub_ezid(shoulder: shoulder, blade: blade)
    end

    it 'mints a new ARK for published SimpleResources' do
      change_set.prepopulate!

      hook.run

      expect(change_set.model.identifier).not_to be_empty
      expect(change_set.model.identifier).to include new_ark
    end
    context 'with an unpublished SimpleResource' do
      let(:simple_resource) { FactoryBot.create(:draft_simple_resource) }
      it 'does not run the hook' do
        change_set.prepopulate!

        hook.run

        expect(hook.run).to be nil
      end
    end
    context 'with an Object of an unsupported Class' do
      let(:change_set) { EphemeraTermChangeSet.new(EphemeraTerm.new) }
      it 'does not run the hook' do
        change_set.prepopulate!

        expect(hook.run).to be nil
      end
    end
  end
end
