# frozen_string_literal: true
require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe DefaultDerivativeService do
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:thumbnail) { Valkyrie::Vocab::PCDMUse.ThumbnailImage }
  let(:derivative_service) do
    DefaultDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_resource) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file], ocr_language: "eng"))
  end
  let(:book_members) { query_service.find_members(resource: scanned_resource) }
  let(:valid_resource) { book_members.first }
  let(:valid_change_set) { ChangeSet.for(valid_resource) }
  let(:valid_id) { valid_change_set.id }

  describe "#valid?" do
    subject(:valid_file) { derivative_service.new(id: valid_change_set.id) }

    context "when given mime_type image/tiff" do
      it { is_expected.to be_valid }
    end

    context "when given mime_type image/jpeg" do
      let(:file) { fixture_file_upload("files/large-jpg-test.jpg", "image/jpeg") }

      it { is_expected.to be_valid }
    end

    context "when given mime_type image/png" do
      let(:file) { fixture_file_upload("files/abstract.png", "image/png") }

      it { is_expected.to be_valid }
    end

    context "when given an intermediate file set" do
      let(:valid_resource) { FactoryBot.create_for_repository(:intermediate_image_file_set) }

      it { is_expected.to be_valid }
    end
  end

  it "creates a JP2 and attaches it to the fileset" do
    # Stub so we can ensure only buffer is used.
    allow(adapter.persister).to receive(:buffer_into_index).and_call_original
    derivative_service.new(id: valid_change_set.id).create_derivatives

    reloaded = query_service.find_by(id: valid_resource.id)
    derivative = reloaded.derivative_file

    expect(derivative).to be_present
    derivative_file = Valkyrie::StorageAdapter.find_by(id: derivative.file_identifiers.first)
    expect(derivative_file.read).not_to be_blank
    # Ensure only one buffer is used.
    # This is important so that callbacks don't fire until all derivatives are
    # created.
    # See https://github.com/pulibrary/figgy/issues/2188
    expect(adapter.persister).to have_received(:buffer_into_index).exactly(1).times
  end

  describe "#cleanup_derivatives" do
    before do
      derivative_service.new(id: valid_change_set.id).create_derivatives
    end

    it "deletes the attached fileset when the resource is deleted" do
      derivative_service.new(id: valid_change_set.id).cleanup_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.file_metadata.select(&:derivative?)).to be_empty
    end
  end
end
