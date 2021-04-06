# frozen_string_literal: true
require "rails_helper"

RSpec.describe OAI::Figgy::ValkyrieProviderModel do
  describe "#deleted?" do
    it "is false" do
      expect(described_class.new).not_to be_deleted
    end
  end

  describe "#find_all" do
    context "when requesting all items" do
      it "returns all complete public resources" do
        create_scanned_resource(source_metadata_identifier: "8543429", collection_id: nil)
        create_scanned_resource(source_metadata_identifier: "8543429", collection_id: nil, state: "pending", visibility: ::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ON_CAMPUS)
        create_scanned_resource(source_metadata_identifier: "8543429", collection_id: nil, state: "complete", visibility: ::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ON_CAMPUS)
        create_scanned_resource(source_metadata_identifier: "8543429", collection_id: nil, state: "complete", rights_statement: RightsStatements.no_copyright_contractual_restrictions)

        output = described_class.new.find_all(metadata_prefix: "marc21")

        expect(output.to_a.length).to eq 1
      end
    end

    context "when requesting the cico set" do
      it "returns only items that are a member of that set" do
        collection = FactoryBot.create_for_repository(:collection, slug: "cico")
        create_scanned_resource(source_metadata_identifier: "8543429", collection_id: collection.id)
        create_scanned_resource(source_metadata_identifier: "123456", collection_id: nil)

        output = described_class.new.find_all(set: "cico", metadata_prefix: "marc21")

        expect(output.length).to eq 1
        expect(output.first).to be_a OAI::Figgy::OAIWrapper
      end

      it "doesn't return volumes" do
        collection = FactoryBot.create_for_repository(:collection, slug: "cico")
        parent = create_scanned_resource(source_metadata_identifier: "123456", collection_id: collection.id)
        create_scanned_resource(source_metadata_identifier: "8543429", collection_id: collection.id, append_id: parent.id)

        output = described_class.new.find_all(set: "cico", metadata_prefix: "marc21")

        expect(output.length).to eq 1
        expect(output.first).to be_a OAI::Figgy::OAIWrapper
      end

      it "can find items within a specific date range" do
        collection = FactoryBot.create_for_repository(:collection, slug: "cico")
        Timecop.freeze(Time.zone.local(2008, 9, 1, 12, 0, 0))
        create_scanned_resource(source_metadata_identifier: "8543429", collection_id: collection.id)
        Timecop.freeze(Time.zone.local(2009, 9, 1, 12, 0, 0))
        new_resource = create_scanned_resource(source_metadata_identifier: "8543429", collection_id: collection.id)
        Timecop.freeze(Time.zone.local(2010, 9, 1, 12, 0, 0))
        create_scanned_resource(source_metadata_identifier: "8543429", collection_id: collection.id)
        Timecop.return

        output = described_class.new.find_all(set: "cico", metadata_prefix: "marc21", from: "2009-09-01T12:00:00Z", until: "2009-12-01T12:00:00Z")

        expect(output.map(&:id)).to eq [new_resource.id]
      end

      it "returns only items that can be converted to MARC21" do
        collection = FactoryBot.create_for_repository(:collection, slug: "cico")
        stub_pulfa(pulfa_id: "AC044_c0003")
        # Return MARC items
        create_scanned_resource(source_metadata_identifier: "8543429", collection_id: collection.id)
        # Don't return items without a metadata identifier
        FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id)
        # Don't return PULFA items - they don't have MARC.
        FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "AC044_c0003", import_metadata: true)

        output = described_class.new.find_all(set: "cico", metadata_prefix: "marc21")

        expect(output.length).to eq 1
        expect(output.first).to be_a OAI::Figgy::OAIWrapper
      end
    end
  end

  context "when there's more than the limit" do
    it "uses resumption tokens" do
      allow(described_class).to receive(:limit).and_return(2)
      collection = FactoryBot.create_for_repository(:collection, slug: "cico")
      3.times do
        create_scanned_resource(source_metadata_identifier: "8543429", collection_id: collection.id)
      end

      output = described_class.new.find_all(set: "cico", metadata_prefix: "marc21")

      expect(output).to be_a OAI::Provider::PartialResult
      expect(output.token.to_xml).to eq "<resumptionToken>marc21.s(cico):0</resumptionToken>"

      next_set = described_class.new.find_all(set: "cico", metadata_prefix: "marc21", resumption_token: "marc21.s(cico):0")

      expect(next_set.length).to eq 1
    end
  end

  def create_scanned_resource(source_metadata_identifier:, collection_id:, member_ids: [], append_id: nil, state: "complete", visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, rights_statement: RightsStatements.no_known_copyright)
    stub_bibdata(bib_id: source_metadata_identifier)
    stub_bibdata(bib_id: source_metadata_identifier, content_type: "application/marcxml+xml") if File.exist?(bibdata_fixture_path(source_metadata_identifier, BibdataStubbing::CONTENT_TYPE_MARC_XML))
    stub_ezid(shoulder: "99999/fk4", blade: source_metadata_identifier)
    FactoryBot.create_for_repository(
      :complete_scanned_resource,
      member_of_collection_ids: collection_id,
      source_metadata_identifier: source_metadata_identifier,
      import_metadata: true,
      member_ids: member_ids,
      append_id: append_id,
      rights_statement: rights_statement,
      state: state,
      visibility: visibility
    )
  end
end
