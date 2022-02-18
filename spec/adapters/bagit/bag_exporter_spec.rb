# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bagit::BagExporter do
  subject(:exporter) do
    described_class.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:bags),
      storage_adapter: Valkyrie::StorageAdapter.find(:bags),
      query_service: Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    )
  end
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  let(:bag_path) { exporter.metadata_adapter.bag_path(id: resource.id) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  after do
    exporter.metadata_adapter.persister.wipe!
  end
  with_queue_adapter :inline
  it "can store a resource as a bag", run_real_derivatives: true do
    resource
    sha_digest = Digest::SHA1.new
    allow(Digest::SHA1).to receive(:new).and_return(sha_digest)
    allow(sha_digest).to receive(:update).and_call_original
    exporter.export(resource: resource)
    # Metadata files for the resource.
    expect(File.exist?(bag_path.join("tagmanifest-sha256.txt"))).to eq true
    expect(File.exist?(bag_path.join("metadata", "#{resource.id}.jsonld"))).to eq true
    # Metadata files for the FileSet
    member_id = resource.member_ids.first
    expect(File.exist?(bag_path.join("metadata", "#{member_id}.jsonld"))).to eq true
    # Binary files for the FileSet
    expect(Dir.glob(bag_path.join("data", "*")).length).to eq 1
    # Adjusts file identifiers so it can pull files back out
    file_set = exporter.metadata_adapter.for(bag_id: resource.id).query_service.find_by(id: member_id)
    expect(file_set.original_file.file_identifiers.first.to_s).to start_with "bag://"
    expect(exporter.storage_adapter.for(bag_id: resource.id).find_by(id: file_set.original_file.file_identifiers.first)).not_to be_blank
    # Don't generate checksums - they already exist.
    expect(sha_digest).not_to have_received(:update)
  end
end
