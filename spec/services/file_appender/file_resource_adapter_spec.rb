# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FileAppender::FileResourceAdapter do
  subject(:file_resource_adapter) { described_class.new(file_resource: file_node) }
  let(:file_set) { instance_double(FileSet) }
  let(:file_metadata) { instance_double(FileMetadata) }
  let(:file_metadata_id) { instance_double(Valkyrie::ID) }
  let(:file_node) { file_metadata }

  describe '#file_metadata' do
    before do
      allow(file_metadata).to receive(:original_filename)
    end
    it 'retrieves the file metadata for the resource' do
      expect(file_resource_adapter.file_metadata).to eq file_metadata
    end

    context 'with a FileSet' do
      let(:file_node) { file_set }

      before do
        allow(file_set).to receive(:file_metadata).and_return(file_metadata)
      end
      it 'retrieves the file metadata for the resource' do
        expect(file_resource_adapter.file_metadata).to eq file_metadata
        expect(file_set).to have_received(:file_metadata)
      end
    end

    context "with an object which isn't a file resource" do
      let(:file_node) { 'this is not a file' }
      it 'raises an error' do
        expect { file_resource_adapter.file_metadata }.to raise_error(NotImplementedError, "Attempted to retrieve the metadata for an unsupported file resource: String")
      end
    end
  end

  describe '#id' do
    before do
      allow(file_metadata).to receive(:id).and_return(file_metadata_id)
    end

    it 'retrieves the ID for the resource' do
      expect(file_resource_adapter.id).to eq file_metadata_id
    end

    context "with an object which isn't a file resource" do
      let(:file_node) { 'this is not a file' }
      it 'raises an error' do
        expect { file_resource_adapter.id }.to raise_error(NotImplementedError, "Attempted to retrieve the ID for an unsupported file resource: String")
      end
    end
  end
end
