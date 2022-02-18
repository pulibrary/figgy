# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChangeSetPersister::MintIdentifier do
  subject(:hook) { described_class.new(change_set_persister: change_set_persister, change_set: change_set) }
  let(:change_set_persister) { instance_double(ChangeSetPersister::Basic, query_service: query_service) }
  let(:change_set) { SimpleChangeSet.new(simple_resource) }
  let(:simple_resource) { FactoryBot.create(:complete_simple_resource) }
  let(:query_service) { instance_double(Valkyrie::Persistence::Memory::QueryService) }

  describe "#run" do
    let(:identifier_service) { class_double(IdentifierService).as_stubbed_const transfer_nested_constants: true }
    let(:shoulder) { "99999/fk4" }
    let(:blade) { "123456" }
    let(:new_ark) { "ark:/#{shoulder}#{blade}" }

    before do
      stub_ezid(shoulder: shoulder, blade: blade)
    end

    it "mints a new ARK for published SimpleResources" do
      change_set.validate(state: :complete)

      hook.run

      expect(change_set.model.identifier).not_to be_empty
      expect(change_set.model.identifier).to include new_ark
    end

    context "when an already published SimpleResource is updated" do
      let(:existing_ark) { "ark:/#{shoulder}234567" }
      let(:simple_resource) { FactoryBot.create(:complete_simple_resource, identifier: existing_ark) }
      before do
        change_set.validate(creator: "Johann Georg Faust")
      end

      it "does not mint a new ARK" do
        expect(hook.run).to be nil
        expect(change_set.model.identifier).to eq [existing_ark]
      end
    end

    context "when an already published SimpleResource has its title updated" do
      let(:existing_ark) { "ark:/#{shoulder}234567" }
      let(:simple_resource) { FactoryBot.create(:complete_simple_resource, identifier: existing_ark) }
      before do
        change_set.validate(title: "Doctor Faustens dreyfacher Höllenzwang")
      end

      it "updates the existing ARK" do
        expect(hook.run).to be_a SimpleChangeSet
        expect(change_set.model.identifier).to eq [existing_ark]
      end
    end
    context "when an already published SimpleResource is added to a collection" do
      let(:existing_ark) { "ark:/#{shoulder}234567" }
      let(:simple_resource) { FactoryBot.create(:complete_simple_resource, identifier: existing_ark) }
      let(:collection) { FactoryBot.create_for_repository(:collection) }
      before do
        change_set.validate(member_of_collection_ids: [collection.id])
      end
      it "does not mint a new ARK" do
        expect(hook.run).to be nil
        expect(change_set.model.identifier).to eq [existing_ark]
      end
    end
    context "when none of the relevant metadata has changed" do
      let(:simple_resource) { FactoryBot.create(:complete_simple_resource, identifier: new_ark) }
      it "does not run the hook" do
        hook.run

        expect(hook.run).to be nil
      end
    end
    context "with an unpublished SimpleResource" do
      let(:simple_resource) { FactoryBot.create(:draft_simple_resource) }
      it "does not run the hook" do
        hook.run

        expect(hook.run).to be nil
      end
    end
    context "with an Object of an unsupported Class" do
      let(:change_set) { EphemeraTermChangeSet.new(EphemeraTerm.new) }
      it "does not run the hook" do
        expect(hook.run).to be nil
      end
    end
  end
end
