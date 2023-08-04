# frozen_string_literal: true
require "rails_helper"

RSpec.describe DeleteDuplicateFixityEvents do
  with_queue_adapter :inline
  subject(:query) { described_class.new(query_service: query_service) }

  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { metadata_adapter.query_service }

  describe "#delete_duplicate_fixity_events" do
    context "when there are multiple current metadata_node events" do
      it "deletes the earliest-created duplicate" do
        # create some duplicates
        ids = Array.new(2) { Valkyrie::ID.new(SecureRandom.uuid) }
        events_to_create = ids.map do |id|
          Array.new(2) do
            FactoryBot.create_for_repository(:cloud_fixity_event, child_property: "metadata_node", resource_id: id, current: true)
          end
        end
        # create a non-current event
        FactoryBot.create_for_repository(:cloud_fixity_event, child_property: "metadata_node", resource_id: ids.first, current: false)
        # create a local fixity event
        FactoryBot.create_for_repository(:local_fixity_success, child_property: "binary_node", resource_id: ids.first, child_id: Valkyrie::ID.new(SecureRandom.uuid), current: true)
        # create a binary node event
        FactoryBot.create_for_repository(:cloud_fixity_event, child_property: "binary_node", resource_id: ids.first, child_id: Valkyrie::ID.new(SecureRandom.uuid), current: true)

        expect(query_service.find_all_of_model(model: Event).count).to eq 7
        query.delete_duplicate_fixity_events
        events = query_service.find_all_of_model(model: Event)
        expect(events.count).to eq 5
        events_to_create.each do |tuple|
          expect { query_service.find_by(id: tuple.first.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
          expect { query_service.find_by(id: tuple.last.id) }.not_to raise_error # (Valkyrie::Persistence::ObjectNotFoundError)
        end
      end
    end
  end
end
