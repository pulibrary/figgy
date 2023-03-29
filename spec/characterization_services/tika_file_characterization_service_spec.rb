# frozen_string_literal: true

require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe TikaFileCharacterizationService do
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
    described_class.new(file_set: valid_file_set, persister: persister).characterize
  end

  context "when given a file with an apostrophe", run_real_characterization: true do
    let(:file) { fixture_file_upload("files/w'eird.tif", "image/tiff") }
    it "works" do
      described_class.new(file_set: valid_file_set, persister: persister).characterize
    end
  end

  it "sets the height attribute for a file_set on characterize " do
    t_file_set = valid_file_set
    t_file_set.original_file.height = nil
    new_file_set = described_class.new(file_set: t_file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.height).not_to be_empty
  end

  it "sets the width attribute for a file_set on characterize" do
    t_file_set = valid_file_set
    t_file_set.original_file.width = nil
    new_file_set = described_class.new(file_set: t_file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.width).not_to be_empty
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

  it "sets the mime_type for a file_set on characterize" do
    t_file_set = valid_file_set
    t_file_set.original_file.mime_type = nil
    new_file_set = described_class.new(file_set: t_file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.mime_type).not_to be_empty
  end

  it "sets the checksum for a file_set on characterize" do
    t_file_set = valid_file_set
    t_file_set.original_file.checksum = nil
    new_file_set = described_class.new(file_set: t_file_set, persister: persister).characterize(save: false)
    checksum = new_file_set.original_file.checksum
    expect(checksum.count).to eq 1
    expect(checksum.first).to be_a MultiChecksum
  end

  it "sets the bits per sample attribute for a file_set on characterize" do
    t_file_set = valid_file_set
    t_file_set.original_file.width = nil
    new_file_set = described_class.new(file_set: t_file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.bits_per_sample).not_to be_empty
  end

  it "sets the x resolution attribute for a file_set on characterize" do
    t_file_set = valid_file_set
    t_file_set.original_file.width = nil
    new_file_set = described_class.new(file_set: t_file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.x_resolution).not_to be_empty
  end

  it "sets the y resolution attribute for a file_set on characterize" do
    t_file_set = valid_file_set
    t_file_set.original_file.width = nil
    new_file_set = described_class.new(file_set: t_file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.y_resolution).not_to be_empty
  end

  it "sets the camera model attribute for a file_set on characterize" do
    t_file_set = valid_file_set
    t_file_set.original_file.width = nil
    new_file_set = described_class.new(file_set: t_file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.camera_model).not_to be_empty
  end

  it "sets the software attribute for a file_set on characterize" do
    t_file_set = valid_file_set
    t_file_set.original_file.width = nil
    new_file_set = described_class.new(file_set: t_file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.software).not_to be_empty
  end

  context "when a file set contains a preservation file and an intermediate file" do
    let(:tika_output) { tika_shapefile_output }
    it "characterizes both files" do
      preservation = fixture_file_upload("files/vector/shapefile.zip", "application/zip", Valkyrie::Vocab::PCDMUse.PreservationFile)
      resource = FactoryBot.create_for_repository(:simple_resource, files: [preservation])
      file_set = query_service.find_members(resource: resource).first
      IngestIntermediateFileJob.perform_now(file_path: Rails.root.join("spec", "fixtures", "files", "vector", "shapefile.zip"), file_set_id: file_set.id)
      file_set = query_service.find_members(resource: resource).first
      expect(file_set.file_metadata[0].checksum).not_to be_empty
      expect(file_set.file_metadata[1].checksum).not_to be_empty
    end
  end

  describe "#valid?" do
    it "returns true" do
      expect(described_class.new(file_set: valid_file_set, persister: persister).valid?).to be true
    end
  end
end
