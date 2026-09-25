require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe GenericFileCharacterizationService do
  it_behaves_like "a Valkyrie::Derivatives::FileCharacterizationService"

  let(:file_characterization_service) { described_class }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:book) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
  end
  let(:book_change_set) do
    ScannedResourceChangeSet.new(ScannedResource.new).tap do |change_set|
      change_set.files = [file]
    end
  end
  let(:book_members) { query_service.find_members(resource: book) }
  let(:valid_file_set) { book_members.first }

  before do
    output = "547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c"
    ruby_mock = instance_double(Digest::SHA256, hexdigest: output)
    allow(Digest::SHA256).to receive(:hexdigest).and_return(ruby_mock)
  end

  it "characterizes a sample file" do
    new_file_set = described_class.new(file_set: valid_file_set, persister: persister).characterize
    expect(new_file_set.original_file).to have_attributes(
      mime_type: ["image/tiff"],
      size: ["196882"]
    )
    expect(new_file_set.original_file.checksum.first).to have_attributes(
      sha256: "547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c",
      md5: "2a28fb702286782b2cbf2ed9a5041ab1",
      sha1: "1b95e65efc3aefeac1f347218ab6f193328d70f5"
    )
  end

  context "when given a file with an apostrophe", run_real_characterization: true do
    let(:file) { fixture_file_upload("files/w'eird.tif", "image/tiff") }
    it "works" do
      described_class.new(file_set: valid_file_set, persister: persister).characterize
    end
  end

  it "saves to the persister by default on characterize" do
    allow(persister).to receive(:save).and_return(valid_file_set)
    described_class.new(file_set: valid_file_set, persister: persister).characterize
    expect(persister).to have_received(:save).once
  end

  it "does not save to the persister when characterize is called with save false" do
    allow(persister).to receive(:save).and_return(valid_file_set)
    described_class.new(file_set: valid_file_set, persister: persister).characterize(save: false)
    expect(persister).not_to have_received(:save)
  end

  context "when a file set contains a preservation file and an intermediate file" do
    let(:tika_output) { tika_shapefile_output }
    it "characterizes both files" do
      preservation = fixture_file_with_use("files/vector/shapefile.zip", "application/zip", ::PcdmUse::PreservationFile)
      resource = FactoryBot.create_for_repository(:simple_resource, files: [preservation])
      file_set = query_service.find_members(resource: resource).first
      IngestIntermediateFileJob.perform_now(file_path: Rails.root.join("spec", "fixtures", "files", "vector", "shapefile.zip"), file_set_id: file_set.id)
      file_set = query_service.find_members(resource: resource).first
      expect(file_set.file_metadata[0].checksum).not_to be_empty
      expect(file_set.file_metadata[1].checksum).not_to be_empty
    end
  end

  context "when provided with a file that can't be processed by anything else", run_real_characterization: true do
    let(:file) { fixture_file_upload("files/empty.tif", "image/tiff") }
    let(:invalid_file_set) { book_members.first }

    it "just adds basic info" do
      described_class.new(file_set: invalid_file_set, persister: persister).characterize
      file_set = query_service.find_by(id: invalid_file_set.id)
      expect(file_set.file_metadata[0].width).to be_empty
      expect(file_set.file_metadata[0].size).to eq ["0"]
    end
  end

  context "when characterization fails and then succeeds" do
    it "removes any previous error messages" do
      allow(Vips::Image).to receive(:new_from_file).and_raise("Error")
      expect { described_class.new(file_set: valid_file_set, persister: persister).characterize }.to raise_error(RuntimeError)
      file_set = query_service.find_by(id: valid_file_set.id)
      expect(file_set.file_metadata[0].error_message.first).to start_with "Error during characterization:"
      allow(Vips::Image).to receive(:new_from_file).and_call_original
      described_class.new(file_set: file_set, persister: persister).characterize
      file_set = query_service.find_by(id: valid_file_set.id)
      expect(file_set.file_metadata[0].error_message).to be_empty
    end
  end

  describe "#valid?" do
    it "returns true" do
      expect(described_class.new(file_set: valid_file_set, persister: persister).valid?).to be true
    end
  end
end
