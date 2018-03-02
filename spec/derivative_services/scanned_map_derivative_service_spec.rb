# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/derivatives/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe ScannedMapDerivativeService do
  with_queue_adapter :inline
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:derivative_service) do
    ScannedMapDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
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

    context "when given an invalid mime_type" do
      it "does not validate" do
        # rubocop:disable RSpec/SubjectStub
        allow(valid_file).to receive(:mime_type).and_return(["image/jpeg"])
        # rubocop:enable RSpec/SubjectStub
        is_expected.not_to be_valid
      end
    end
  end

  it "creates a JP2 intermediate file and a thumbnail" do
    resource = query_service.find_by(id: valid_resource.id)
    jp2s = resource.file_metadata.find_all { |f| f.label == ["intermediate_file.jp2"] }
    thumbnails = resource.file_metadata.find_all { |f| f.label == ["thumbnail.png"] }
    expect(jp2s.count).to eq 1
    expect(thumbnails.count).to eq 1
  end

  describe '#cleanup_derivatives' do
    it "deletes the attached fileset when the resource is deleted" do
      derivative_service.new(valid_change_set).cleanup_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.file_metadata.select(&:derivative?)).to be_empty
    end
  end
end
