# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindPendingUploadFailures do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:resource1) do
    FactoryBot.create_for_repository(
      :pending_scanned_resource,
      pending_uploads: []
    )
  end
  let(:resource2) do
    FactoryBot.create_for_repository(
      :complete_scanned_resource
    )
  end

  describe "#find_pending_upload_failures" do
    it "can find resources where uploads failed to append files to a resource" do
      resource1
      resource2
      output = query.find_pending_upload_failures.to_a
      expect(output.map(&:id)).to include resource1.id
      expect(output.map(&:id)).not_to include resource2.id
    end
  end
end
