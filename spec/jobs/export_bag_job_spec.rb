# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExportBagJob do
  describe ".perform" do
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
    let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
    let(:bag_metadata) { Valkyrie::MetadataAdapter.find(:bags).for(bag_id: resource.id) }
    let(:bag_storage) { Valkyrie::StorageAdapter.find(:bags) }
    let(:bag_query) { bag_metadata.query_service }

    it "exports the object" do
      described_class.perform_now(resource.id)
      bag_resource = bag_query.find_by(id: resource.id)
      bag_fileset = bag_query.find_by(id: bag_resource.member_ids.first)
      file_id = bag_fileset.original_file.file_identifiers.first
      expect { bag_storage.for(bag_id: bag_resource.id).find_by(id: file_id) }.not_to raise_error
    end
  end
end
