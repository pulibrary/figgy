# frozen_string_literal: true
require "rails_helper"

describe BulkUpdateJob do
  with_queue_adapter :inline
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { metadata_adapter.query_service }

  let(:user) { FactoryBot.create(:staff) }
  let(:resource1) { FactoryBot.create_for_repository(:scanned_resource, state: "pending") }
  let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, state: "pending") }
  let(:ids) { [resource1.id, resource2.id] }
  let(:args) { { mark_complete: true } }
  let(:more_args) { { mark_complete: true, ocr_language: "eng" } }
  let(:all_args) do
    { mark_complete: true,
      ocr_language: "eng",
      rights_statement: "http://rightsstatements.org/vocab/NoC-OKLR/1.0/",
      visibility: "reading_room",
      holding_location: "https://bibdata.princeton.edu/locations/delivery_locations/1" }
  end

  describe "#perform" do
    before do
      resource1
      resource2
      stub_ezid
    end

    it "updates the resource state" do
      described_class.perform_now(ids: ids, email: user.email, args: more_args, time: Time.current, search_params: {})
      r1 = query_service.find_by(id: resource1.id)
      r2 = query_service.find_by(id: resource2.id)
      expect(r1.state).to eq ["complete"]
      expect(r1.ocr_language).to eq ["eng"]
      expect(r2.state).to eq ["complete"]
      expect(r2.ocr_language).to eq ["eng"]
    end

    it "appends to and removes from collections" do
      collection = FactoryBot.create_for_repository(:collection)
      described_class.perform_now(ids: ids, email: user.email, args: { append_collection_ids: [collection.id.to_s] }, time: Time.current, search_params: {})
      r1 = query_service.find_by(id: resource1.id)
      r2 = query_service.find_by(id: resource2.id)
      expect(r1.member_of_collection_ids).to eq [collection.id]
      expect(r2.member_of_collection_ids).to eq [collection.id]

      described_class.perform_now(ids: ids, email: user.email, args: { remove_collection_ids: [collection.id.to_s] }, time: Time.current, search_params: {})
      r1 = query_service.find_by(id: resource1.id)
      r2 = query_service.find_by(id: resource2.id)
      expect(r1.member_of_collection_ids).to be_empty
      expect(r2.member_of_collection_ids).to be_empty
    end

    it "doesn't change values not specified" do
      described_class.perform_now(ids: ids, email: user.email, args: more_args, time: Time.current, search_params: {})
      r1 = query_service.find_by(id: resource1.id)
      r2 = query_service.find_by(id: resource2.id)
      expect(r1.visibility).to eq ["open"]
      expect(r1.rights_statement).to eq ["http://rightsstatements.org/vocab/NKC/1.0/"]
      expect(r1.holding_location).to eq nil
      expect(r2.visibility).to eq ["open"]
      expect(r2.rights_statement).to eq ["http://rightsstatements.org/vocab/NKC/1.0/"]
      expect(r2.holding_location).to eq nil
    end

    context "updating all of the available attributes" do
      it "updates the resource state" do
        described_class.perform_now(ids: ids, email: user.email, args: all_args, time: Time.current, search_params: {})
        r1 = query_service.find_by(id: resource1.id)
        r2 = query_service.find_by(id: resource2.id)
        expect(r1.state).to eq ["complete"]
        expect(r1.ocr_language).to eq ["eng"]
        expect(r1.rights_statement).to eq ["http://rightsstatements.org/vocab/NoC-OKLR/1.0/"]
        expect(r1.visibility).to eq ["reading_room"]
        expect(r1.holding_location.map(&:to_s)).to eq ["https://bibdata.princeton.edu/locations/delivery_locations/1"]
        expect(r2.state).to eq ["complete"]
        expect(r2.ocr_language).to eq ["eng"]
        expect(r2.rights_statement).to eq ["http://rightsstatements.org/vocab/NoC-OKLR/1.0/"]
        expect(r2.visibility).to eq ["reading_room"]
        expect(r2.holding_location.map(&:to_s)).to eq ["https://bibdata.princeton.edu/locations/delivery_locations/1"]
      end
    end

    context "one of the resources is taken down" do
      let(:resource2) do
        Timecop.freeze(Time.now.utc - 1.day) do
          FactoryBot.create_for_repository(:scanned_resource, state: "takedown")
        end
      end
      it "doesn't persist the one that was marked taken down" do
        described_class.perform_now(ids: ids, email: user.email, args: args, time: Time.current, search_params: {})
        r2 = query_service.find_by(id: resource2.id)
        expect(r2.updated_at.to_date).to be < Time.current.to_date
        expect(r2.state).to eq ["takedown"]
      end
    end

    context "one of the resources was already complete" do
      let(:resource2) do
        Timecop.freeze(Time.now.utc - 1.day) do
          FactoryBot.create_for_repository(:scanned_resource, state: "complete")
        end
      end
      it "doesn't persist the one that was already complete" do
        described_class.perform_now(ids: ids, email: user.email, args: args, time: Time.current, search_params: {})
        r2 = query_service.find_by(id: resource2.id)
        expect(r2.updated_at.to_date).to be < Time.current.to_date
      end
    end

    context "there's a validation error on one of the change sets" do
      let(:change_set) { ChangeSet.for(resource1) }
      before do
        allow(ChangeSet).to receive(:for).and_return(change_set)
        allow(change_set).to receive(:valid?).and_return(false)
      end
      it "Sends an email notice" do
        expect { described_class.perform_now(ids: ids, email: user.email, args: args, time: Time.current, search_params: {}) }
          .to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end
