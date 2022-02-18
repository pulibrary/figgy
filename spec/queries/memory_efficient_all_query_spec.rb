# frozen_string_literal: true

require "rails_helper"

describe MemoryEfficientAllQuery do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

  describe "#memory_efficient_all" do
    context "when not given any arguments" do
      it "finds all" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        expect(query.memory_efficient_all.map(&:id).to_a).to eq [resource.id]
      end
    end

    it "will only parse as many objects as is necessary" do
      5.times { FactoryBot.create_for_repository(:scanned_resource) }
      allow(query_service.resource_factory).to receive(:to_resource).and_call_original
      expect(query.memory_efficient_all.first(2).length).to eq 2
      expect(query_service.resource_factory).to have_received(:to_resource).exactly(2).times
    end

    context "when given except_models argument" do
      it "finds everything that isn't one of those models" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        FactoryBot.create_for_repository(:processed_event)
        FactoryBot.create_for_repository(:file_set)

        expect(query.memory_efficient_all(except_models: [ProcessedEvent, FileSet]).map(&:id).to_a).to eq [resource.id]
      end
    end
  end
end
