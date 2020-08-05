# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileSet do
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  before do
    stub_ezid(shoulder: shoulder, blade: blade)
  end

  describe "optimistic locking" do
    it "is enabled" do
      expect(described_class.optimistic_locking_enabled?).to eq true
    end
  end

  describe "#primary_file" do
    context "when there is an original file" do
      it "returns that" do
        fm = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.OriginalFile)
        fm2 = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.PreservationMasterFile)
        fm3 = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.IntermediateFile)
        fs = FactoryBot.build(:file_set, file_metadata: [fm, fm2, fm3])
        expect(fs.primary_file).to eq fm
      end
    end

    context "when there is a preservation file and no original file" do
      it "returns the preservation file" do
        fm = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.PreservationMasterFile)
        fm2 = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.IntermediateFile)
        fs = FactoryBot.build(:file_set, file_metadata: [fm, fm2])
        expect(fs.primary_file).to eq fm
      end
    end

    context "when there is only an intermediate file" do
      it "returns that" do
        fm = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.IntermediateFile)
        fs = FactoryBot.build(:file_set, file_metadata: [fm])
        expect(fs.primary_file).to eq fm
      end
    end
  end

  describe "processing_status" do
    it "is a property" do
      expect(described_class.schema.key?(:processing_status)).to eq true
    end
  end

  describe ".run_fixity" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:resource) { FactoryBot.build(:scanned_resource) }
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie.config.storage_adapter }
    let(:query_service) { adapter.query_service }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
    let(:change_set) { ScannedResourceChangeSet.new(resource) }
    let(:output) do
      change_set.files = [file]
      change_set_persister.save(change_set: change_set)
    end

    before do
      # it has to be charaterized to compare the checksums,
      # and it has to be saved to characterize
      file_set = query_service.find_members(resource: output).first
      CharacterizationJob.perform_now(file_set.id.to_s)
    end

    describe "when check succeeds" do
      it "sets fixity attributes as successful" do
        # neet to reload the file_set after characterization has run
        file_set = query_service.find_members(resource: output).first
        original_file_metadata = file_set.run_fixity
        expect(original_file_metadata).to be_a FileMetadata
        expect(original_file_metadata.fixity_success).to eq 1
        expect(original_file_metadata.fixity_actual_checksum.first).to be_a MultiChecksum
        expect(original_file_metadata.fixity_last_success_date).to be_a Time
      end
    end

    describe "when check fails" do
      before do
        file_set = query_service.find_members(resource: output).first
        filename = file_set.original_file.file_identifiers[0].to_s.gsub("disk://", "")
        new_file = File.join(fixture_path, "files/color-landscape.tif")
        FileUtils.cp(new_file, filename)
        allow(Honeybadger).to receive(:notify)
      end

      it "sets the fixity attributes according to failure and notifies Honeybadger" do
        file_set = query_service.find_members(resource: output).first
        original_file_metadata = file_set.run_fixity
        expect(original_file_metadata.fixity_success).to eq 0
        expect(original_file_metadata.fixity_actual_checksum.first).to be_a MultiChecksum
        expect(original_file_metadata.fixity_last_success_date).to be_nil
        expect(Honeybadger).to have_received(:notify)
      end

      it "does not run again" do
        file_set = query_service.find_members(resource: output).first
        original_file_metadata = file_set.run_fixity
        expect(original_file_metadata.fixity_success).to eq 0
        file_set.file_metadata = file_set.file_metadata.select { |x| !x.original_file? } + Array.wrap(original_file_metadata)
        adapter.persister.save(resource: file_set)
        file_set = query_service.find_members(resource: output).first
        allow(MultiChecksum).to receive(:for).and_call_original
        file_set.run_fixity
        expect(MultiChecksum).not_to have_received(:for)
      end
    end
  end
end
