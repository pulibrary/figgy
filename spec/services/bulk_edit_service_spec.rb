# frozen_string_literal: true
require "rails_helper"

RSpec.describe BulkEditService do
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:collection) { FactoryBot.create_for_repository(:collection) }
  let(:collection2) { FactoryBot.create_for_repository(:collection) }
  let(:logger) { Logger.new(nil) }
  let(:initial_rights) { RightsStatements.no_known_copyright }
  let(:new_rights) { RightsStatements.copyright_not_evaluated }
  let(:bad_rights) { RDF::URI("http://rightsstatements.org/vocab/BAD/1.0/") }

  describe "#perform" do
    context "when updating state" do
      before do
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
      end

      it "updates the state of the member objects and mints an ark" do
        obj1 = FactoryBot.create_for_repository(:scanned_resource, state: ["pending"], member_of_collection_ids: [collection.id])

        attrs = { state: "complete" }
        described_class.perform(collection_id: collection.id, attributes: attrs, logger: logger)

        after = query_service.find_by(id: obj1.id)
        expect(after.state).to eq(["complete"])
        expect(after.identifier).to eq(["ark:/99999/fk4123456"])
      end
    end

    context "when updating rights_statement" do
      it "succeeds" do
        obj1 = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id], state: ["pending"], rights_statement: initial_rights)

        attrs = { rights_statement: new_rights }
        described_class.perform(collection_id: collection.id, attributes: attrs, logger: logger)

        after = query_service.find_by(id: obj1.id)
        expect(after.rights_statement).to eq([new_rights])
      end
    end

    context "when change set validation fails" do
      let(:logger) { instance_double ActiveSupport::Logger }

      before do
        allow(logger).to receive(:info)
        allow(logger).to receive(:warn)
      end

      it "logs an error and doesn't change the object" do
        obj = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id], rights_statement: initial_rights)

        attrs = { rights_statement: bad_rights }
        described_class.perform(collection_id: collection.id, attributes: attrs, logger: logger)

        expect(logger).to have_received(:warn).with("  Failed validation: Rights statement http://rightsstatements.org/vocab/BAD/1.0/ is not a valid rights_statement is not a valid rights_statement")
        after = query_service.find_by(id: obj.id)
        expect(after.rights_statement).to eq([initial_rights])
      end
    end

    context "when updating multiple objects and multiple attributes" do
      before do
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
      end

      it "updates them all" do
        obj1 = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id], state: ["pending"], rights_statement: initial_rights)
        obj2 = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id], state: ["pending"], rights_statement: initial_rights)

        attrs = { rights_statement: new_rights, state: "complete" }
        described_class.perform(collection_id: collection.id, attributes: attrs, logger: logger)

        after = query_service.find_by(id: obj1.id)
        expect(after.rights_statement).to eq([new_rights])
        expect(after.state).to eq(["complete"])

        after = query_service.find_by(id: obj2.id)
        expect(after.rights_statement).to eq([new_rights])
        expect(after.state).to eq(["complete"])
      end
    end

    context "when updating collection_ids" do
      it "adds to the existing collection set" do
        obj = FactoryBot.create_for_repository(:scanned_resource,
                                               member_of_collection_ids: [collection.id],
                                               title: "original")
        attrs = { append_collection_ids: collection2.id, title: "updated" }
        described_class.perform(collection_id: collection.id, attributes: attrs, logger: logger)

        after = query_service.find_by(id: obj.id)
        expect(after.member_of_collection_ids).to include(collection.id)
        expect(after.member_of_collection_ids).to include(collection2.id)
        expect(after.title).to eq(["updated"])
      end
    end
  end
end
