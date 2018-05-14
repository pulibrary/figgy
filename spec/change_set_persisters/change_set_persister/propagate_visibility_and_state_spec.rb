# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::PropagateVisibilityAndState do
  subject(:hook) { described_class.new(change_set_persister: change_set_persister, change_set: change_set) }
  let(:change_set_persister) { instance_double(ChangeSetPersister::Basic, query_service: query_service) }
  let(:change_set) { ScannedResourceChangeSet.new(scanned_resource) }
  let(:scanned_resource) { ScannedResource.new }
  let(:query_service) { instance_double(Valkyrie::Persistence::Memory::QueryService) }

  describe "#run" do
    context "when visibility and state haven't been updated" do
      it "doesn't query for it" do
        change_set.prepopulate!
        allow(query_service).to receive(:find_members)

        hook.run

        expect(query_service).not_to have_received(:find_members)
      end
    end
    context "when visibility or state have been updated" do
      it "queries for children" do
        change_set.prepopulate!
        change_set.validate(state: "complete")
        allow(query_service).to receive(:find_members).and_return([])

        hook.run

        expect(query_service).to have_received(:find_members)
      end
    end
  end
end
