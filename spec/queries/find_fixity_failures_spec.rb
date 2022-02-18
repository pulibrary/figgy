# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindFixityFailures do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:file_metadata) { FileMetadata.new(fixity_success: 0) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: file_metadata) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_fixity_failures" do
    it "can find file_sets with metadata fixity_success == 0" do
      file_set
      output = query.find_fixity_failures.first
      expect(output.id).to eq file_set.id
    end
  end
end
