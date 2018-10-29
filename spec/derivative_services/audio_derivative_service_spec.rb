# frozen_string_literal: true
require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"
include ActionDispatch::TestProcess

RSpec.describe AudioDerivativeService do
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"
  let(:derivative_service) do
    AudioDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/audio_file.wav", "audio/x-wav") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_resource) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
  end
  let(:book_members) { query_service.find_members(resource: scanned_resource) }
  let(:valid_resource) { book_members.first }
  let(:valid_change_set) { DynamicChangeSet.new(valid_resource) }

  describe "#valid?" do
    subject(:valid_file) { derivative_service.new(valid_change_set) }

    context "when given a wav mime_type" do
      it { is_expected.to be_valid }
    end

    context "when given an invalid mime_type" do
      it "does not validate" do
        # rubocop:disable RSpec/SubjectStub
        allow(valid_file).to receive(:mime_type).and_return(["image/not-valid"])
        # rubocop:enable RSpec/SubjectStub
        is_expected.not_to be_valid
      end
    end
  end

  describe "#create_derivatives" do
    it "creates an MP3 and attaches it to the fileset" do
      derivative_service.new(valid_change_set).create_derivatives

      reloaded = query_service.find_by(id: valid_resource.id)
      derivative = reloaded.derivative_file

      expect(derivative).to be_present
      expect(derivative.mime_type).to eq ["audio/mp3"]
      derivative_file = Valkyrie::StorageAdapter.find_by(id: derivative.file_identifiers.first)
      expect(derivative_file.read).not_to be_blank
    end
  end

  describe "#cleanup_derivatives" do
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
