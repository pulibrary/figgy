# frozen_string_literal: true
require "rails_helper"

RSpec.describe PreservationObjectChangeSet do
  subject(:change_set) { described_class.new(resource) }

  let(:resource) { FactoryBot.build(:preservation_object) }
  let(:change_set_persister) { ChangeSetPersister.default }

  describe "#preserve?" do
    it "is not preserved" do
      expect(change_set.preserve?).to be false
    end
  end

  describe "deletion" do
    it "deletes events that reference it" do
      preservation_object = FactoryBot.create_for_repository(:preservation_object)
      event = FactoryBot.create_for_repository(:event, resource_id: preservation_object.id)

      change_set_persister.delete(change_set: ChangeSet.for(preservation_object))

      expect { change_set_persister.query_service.find_by(id: event.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end
  end
end
