# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bagit::BagImporter do
  subject(:importer) do
    described_class.new(
      bag_metadata_adapter: Valkyrie::MetadataAdapter.find(:bags),
      bag_storage_adapter: Valkyrie::StorageAdapter.find(:bags),
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk)
    )
  end
  let(:exporter) do
    Bagit::BagExporter.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:bags),
      storage_adapter: Valkyrie::StorageAdapter.find(:bags),
      query_service: Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    )
  end
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  let(:bag_path) { importer.metadata_adapter.bag_path(id: resource.id) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  before do
    exporter.export(resource: resource)
    importer.metadata_adapter.persister.wipe!
  end
  after do
    importer.bag_metadata_adapter.persister.wipe!
  end
  with_queue_adapter :inline
  it "can import a given resource ID" do
    output = importer.import(id: resource.id)
    expect(output).to be_a ScannedResource
    # Check FileSets
    members = importer.metadata_adapter.query_service.find_members(resource: output)
    expect(members.to_a.length).to eq 1
    # Ensure files get moved over.
    file_set = members.first
    expect(file_set.original_file.file_identifiers.first.to_s).to start_with "disk://"
    expect(importer.storage_adapter.find_by(id: file_set.original_file.file_identifiers.first)).not_to be_blank
    # Ensure it generates derivatives
    expect(file_set.derivative_file).to be_present
    # Make sure no extra objects are created.
    expect(importer.metadata_adapter.query_service.find_all.to_a.length).to eq 2
  end
end
