# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileAppender::FileResources do
  subject(:file_resources) { described_class.new(file_nodes) }
  let(:file_set) { instance_double(FileSet) }
  let(:file_set_metadata) { instance_double(FileMetadata) }
  let(:file_set_id) { instance_double(Valkyrie::ID) }
  let(:file_metadata) { instance_double(FileMetadata) }
  let(:file_metadata_id) { instance_double(Valkyrie::ID) }
  let(:file_nodes) { [file_set, file_metadata] }

  describe "#file_metadata" do
    before do
      allow(file_set).to receive(:file_metadata).and_return(file_set_metadata)
      allow(file_metadata).to receive(:original_filename)
    end
    it "retrieves the file metadata for each file resource element" do
      expect(file_resources.file_metadata).to be_an Array
      expect(file_resources.file_metadata.length).to eq 2
      expect(file_resources.file_metadata.first).to eq file_set_metadata
      expect(file_resources.file_metadata.last).to eq file_metadata
    end
    context "with elements which aren't file resources" do
      let(:file_nodes) { [file_set, file_metadata, "foo"] }

      it "raises an error" do
        expect { file_resources.file_metadata }.to raise_error(NotImplementedError, "Attempted to retrieve the metadata for an unsupported file resource: String")
      end
    end
  end

  describe "#ids" do
    before do
      allow(file_set).to receive(:id).and_return(file_set_id)
      allow(file_metadata).to receive(:id).and_return(file_metadata_id)
    end
    it "retrieves the ID for each file resource element" do
      expect(file_resources.ids).to be_an Array
      expect(file_resources.ids.length).to eq 2
      expect(file_resources.ids.first).to eq file_set_id
      expect(file_resources.ids.last).to eq file_metadata_id
    end
    context "with elements which aren't file resources" do
      let(:file_nodes) { [file_set, file_metadata, "foo"] }

      it "raises an error" do
        expect { file_resources.ids }.to raise_error(NotImplementedError, "Attempted to retrieve the ID for an unsupported file resource: String")
      end
    end
  end
end
