# frozen_string_literal: true
require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"
include ActionDispatch::TestProcess

RSpec.describe ImageDerivativeService do
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:derivative_service) do
    ImageDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_map) do
    change_set_persister.save(change_set: ScannedMapChangeSet.new(ScannedMap.new, files: [file]))
  end
  let(:scanned_map_members) { query_service.find_members(resource: scanned_map) }
  let(:valid_resource) { scanned_map_members.first }
  let(:valid_change_set) { DynamicChangeSet.new(valid_resource) }

  describe "#valid?" do
    subject(:valid_file) { derivative_service.new(valid_change_set) }

    context "when given a valid mime_type" do
      it { is_expected.to be_valid }
    end
  end

  it "creates a JPEG thumbnail and attaches it to the fileset" do
    derivative_service.new(valid_change_set).create_derivatives
    reloaded = query_service.find_by(id: valid_resource.id)
    thumbnail = reloaded.thumbnail_files.first
    expect(thumbnail).to be_present
    thumbnail_file = Valkyrie::StorageAdapter.find_by(id: thumbnail.file_identifiers.first)
    image = MiniMagick::Image.open(thumbnail_file.disk_path)
    expect(image.width).to eq 200
    expect(image.height).to eq 287
  end

  describe "#cleanup_derivatives" do
    before do
      derivative_service.new(valid_change_set).create_derivatives
    end

    it "deletes the attached fileset when the resource is deleted" do
      derivative_service.new(valid_change_set).cleanup_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.file_metadata.select { |file| (file.derivative? || file.thumbnail_file?) && file.mime_type.include?(image_mime_type) }).to be_empty
    end
  end
end
