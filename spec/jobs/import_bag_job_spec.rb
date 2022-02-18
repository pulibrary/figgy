# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImportBagJob do
  describe ".perform" do
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
    let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
    let(:bag_metadata) { Valkyrie::MetadataAdapter.find(:bags).for(bag_id: resource.id) }
    let(:bag_storage) { Valkyrie::StorageAdapter.find(:bags) }
    let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }

    it "imports the object" do
      id = resource.id
      ExportBagJob.perform_now(id)
      metadata_adapter.persister.wipe!

      described_class.perform_now(id)

      resource = metadata_adapter.query_service.find_by(id: id)
      fileset = metadata_adapter.query_service.find_by(id: resource.member_ids.first)
      expect(fileset).to be_present
    end
  end
end
