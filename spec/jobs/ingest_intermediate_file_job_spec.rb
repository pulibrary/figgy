# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestIntermediateFileJob do
  describe "#perform" do
    let(:master_file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:file_path) { Rails.root.join("spec", "fixtures", "files", "abstract.tiff") }
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [master_file]) }
    let(:file_set) { resource.decorate.decorated_file_sets.first }
    let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
    let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:change_set_persister) do
      ChangeSetPersister.new(
        metadata_adapter: metadata_adapter,
        storage_adapter: storage_adapter
      )
    end

    it "ingests a file and appends it to an existing resource as an intermediate file" do
      described_class.perform_now(file_path: file_path, file_set_id: file_set.id)
      updated_file_set = metadata_adapter.query_service.find_by(id: file_set.id)

      expect(updated_file_set.file_metadata).not_to be_empty

      intermed_file_metadata = updated_file_set.file_metadata.find { |metadata| metadata.use.include? Valkyrie::Vocab::PCDMUse.IntermediateFile }
      expect(intermed_file_metadata).not_to be_nil

      expect(intermed_file_metadata.original_filename).to include "abstract.tiff"
      expect(intermed_file_metadata.use).to eq [Valkyrie::Vocab::PCDMUse.IntermediateFile]
      expect(intermed_file_metadata.label).to include "abstract.tiff"
    end

    context "when the existing resource has FileSets" do
      let(:second_file) { double("File") }
      let(:cleanup_files_job) { class_double("CleanupFilesJob").as_stubbed_const(transfer_nested_constants: true) }
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [master_file]) }

      before do
        allow(second_file).to receive(:original_filename).and_return("example.tif")
        allow(second_file).to receive(:content_type).and_return("image/tiff")
        allow(second_file).to receive(:use).and_return(Valkyrie::Vocab::PCDMUse.ServiceFile)
        allow(second_file).to receive(:path).and_return(
          Rails.root.join("spec", "fixtures", "files", "example.tif")
        )

        allow(cleanup_files_job).to receive(:set).and_return(cleanup_files_job)
        allow(cleanup_files_job).to receive(:perform_now)
      end

      it "deletes the existing derivatives" do
        change_set = FileSetChangeSet.new(file_set)
        change_set.validate(files: [second_file])
        change_set.sync
        change_set_persister.save(change_set: change_set)
        updated_file_set = metadata_adapter.query_service.find_by(id: file_set.id)
        file_identifiers = updated_file_set.derivative_files.map { |derivative_file| derivative_file.file_identifiers.first }

        described_class.perform_now(file_path: file_path, file_set_id: file_set.id)

        expect(cleanup_files_job).to have_received(:perform_now).with(file_identifiers: file_identifiers)
        file_set_with_intermediates = metadata_adapter.query_service.find_by(id: file_set.id)
        expect(file_set_with_intermediates.derivative_files.length).to eq(1)
      end
    end

    context "when the ChangeSet does not validate when persisting" do
      before do
        allow_any_instance_of(FileSetChangeSet).to receive(:validate).and_return(false)
      end

      it "ingests a file and appends it to an existing resource as an intermediate file" do
        described_class.perform_now(file_path: file_path, file_set_id: file_set.id)
        updated_file_set = metadata_adapter.query_service.find_by(id: file_set.id)

        expect(updated_file_set.file_metadata.length).to eq(1)
      end
    end
  end
end
