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
      described_class.perform_now(ids, args)
    end

    it "updates the resource state" do
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
        r2 = query_service.find_by(id: resource2.id)
        expect(r2.updated_at.to_date).to be < Time.current.to_date
      end
    end
  end
end
