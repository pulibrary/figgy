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
