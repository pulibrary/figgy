# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe ManifestBuilder do
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
  let(:scanned_resource) { FactoryGirl.create_for_repository(:scanned_resource) }
  let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file]) }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
  describe "#build" do
    before do
      change_set_persister.save(change_set: change_set)
    end

    it "generates a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["sequences"].length).to eq 1
    end
  end
end
