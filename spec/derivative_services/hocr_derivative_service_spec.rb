# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/derivatives/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe HocrDerivativeService do
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:thumbnail) { Valkyrie::Vocab::PCDMUse.ThumbnailImage }
  let(:derivative_service) do
    HocrDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload('files/abstract.tiff', 'image/tiff') }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_resource) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new(ocr_language: "eng"), files: [file]))
  end
  let(:book_members) { query_service.find_members(resource: scanned_resource) }
  let(:valid_resource) { book_members.first }
  let(:valid_change_set) { DynamicChangeSet.new(valid_resource) }

  describe '#valid?' do
    subject(:valid_file) { derivative_service.new(valid_change_set) }

    context 'when given a tiff mime_type' do
      it { is_expected.to be_valid }
    end

    context 'when given a jpeg mime_type' do
      it 'is valid' do
        # rubocop:disable RSpec/SubjectStub
        allow(valid_file).to receive(:mime_type).and_return(['image/jpeg'])
        # rubocop:enable RSpec/SubjectStub
        is_expected.to be_valid
      end
    end

    context 'when given an invalid mime_type' do
      it 'does not validate' do
        # rubocop:disable RSpec/SubjectStub
        allow(valid_file).to receive(:mime_type).and_return(['image/not-valid'])
        # rubocop:enable RSpec/SubjectStub
        is_expected.not_to be_valid
      end
    end
  end

  context 'tiff source' do
    it "creates an HOCR file and attaches it as a property to the fileset" do
      derivative_service.new(valid_change_set).create_derivatives

      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.hocr_content).not_to be_blank
      expect(reloaded.ocr_content).not_to be_blank
    end
  end

  context 'jpeg source' do
    let(:file) { fixture_file_upload('files/large-jpg-test.jpg', 'image/jpeg') }
    it "creates an HOCR file and attaches it to the fileset" do
      derivative_service.new(valid_change_set).create_derivatives

      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.hocr_content).not_to be_blank
    end
  end
end
