# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/derivatives/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe PlumDerivativeService do
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:thumbnail) { Valkyrie::Vocab::PCDMUse.ThumbnailImage }
  let(:derivative_service) do
    PlumDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_resource) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
  end
  let(:book_members) { query_service.find_members(resource: scanned_resource) }
  let(:valid_resource) { book_members.first }
  let(:valid_change_set) { DynamicChangeSet.new(valid_resource) }

  describe '#valid?' do
    subject(:valid_file) { derivative_service.new(valid_change_set) }

    context 'when given a valid mime_type' do
      it { is_expected.to be_valid }
    end
  end

  it "creates a JP2 and attaches it to the fileset" do
    derivative_service.new(valid_change_set).create_derivatives

    reloaded = query_service.find_by(id: valid_resource.id)
    derivative = reloaded.derivative_file

    expect(derivative).to be_present
    derivative_file = Valkyrie::StorageAdapter.find_by(id: derivative.file_identifiers.first)
    expect(derivative_file.read).not_to be_blank
  end

  describe '#cleanup_derivatives' do
    before do
      derivative_service.new(valid_change_set).create_derivatives
    end

    it "deletes the attached fileset when the resource is deleted" do
      derivative_service.new(valid_change_set).cleanup_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.file_metadata.select(&:derivative?)).to be_empty
    end
  end
end
