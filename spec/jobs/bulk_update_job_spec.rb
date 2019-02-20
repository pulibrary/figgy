# frozen_string_literal: true
require "rails_helper"

describe BulkUpdateJob do
  with_queue_adapter :inline
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { metadata_adapter.query_service }

  let(:resource1) { FactoryBot.create_for_repository(:scanned_resource, state: "pending") }
  let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, state: "pending") }
  let(:ids) { [resource1.id, resource2.id] }
  let(:args) { { mark_complete: true } }
  describe "#perform" do
    before do
      resource1
      resource2
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end

    it "updates the resource state" do
      described_class.perform_now(ids: ids, args: args)
      r1 = query_service.find_by(id: resource1.id)
      r2 = query_service.find_by(id: resource2.id)
      expect(r1.state).to eq ["complete"]
      expect(r2.state).to eq ["complete"]
    end

    context "one of the resources was already complete" do
      let(:resource2) do
        Timecop.freeze(Time.now.utc - 1.day) do
          FactoryBot.create_for_repository(:scanned_resource, state: "complete")
        end
      end
      it "doesn't persist the one that was already complete" do
        described_class.perform_now(ids: ids, args: args)
        r2 = query_service.find_by(id: resource2.id)
        expect(r2.updated_at.to_date).to be < Time.current.to_date
      end
    end

    context "there's a validation error on one of the change sets" do
      let(:change_set) { DynamicChangeSet.new(resource1) }
      before do
        allow(DynamicChangeSet).to receive(:new).and_return(change_set)
        allow(change_set).to receive(:valid?).and_return(false)
      end
      it "raises an error" do
        expect { described_class.perform_now(ids: ids, args: args) }.to raise_error(
          "Bulk update failed for batch #{ids} with args #{args} due to invalid change set on resource #{resource1.id}"
        )
      end
    end
  end
end
