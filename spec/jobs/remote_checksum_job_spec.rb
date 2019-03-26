# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe RemoteChecksumJob do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  let(:file_set) { scanned_resource.decorate.file_sets.first }

  before do
    WebMock.disable!
  end

  describe ".perform_now" do
    it "triggers a derivatives_created message", rabbit_stubbed: true do
      described_class.perform_now(file_set.id.to_s)
      reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: file_set.id)

      expect(reloaded.remote_checksum).to eq ["Kij7cCKGeCssvy7ZpQQasQ=="]
    end
  end
end
