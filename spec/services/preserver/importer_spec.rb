# frozen_string_literal: true
require "rails_helper"

describe Preserver::Importer do
  with_queue_adapter :inline

  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, files: [file]) }
  let(:file_set) { resource.decorate.file_sets.first }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { change_set_persister.query_service }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:google_cloud_storage) }
  let(:persisted_resource) do
    reloaded_resource = query_service.find_by(id: resource.id)
    change_set_persister.metadata_adapter.persister.save(resource: reloaded_resource)
  end
  let(:persisted_file_set) do
    file_set.read_groups = []
    file_set.primary_file.use = [Valkyrie::Vocab::PCDMUse.IntermediateFile]
    change_set_persister.metadata_adapter.persister.save(resource: file_set)
  end
  let(:preservation_object) do
    wayfinder = Wayfinder.for(persisted_file_set)
    wayfinder.preservation_object
  end
  let(:metadata_file_identifier) do
    file_metadata = preservation_object.metadata_node
    file_metadata.file_identifiers.first
  end
  let(:binary_file_identifiers) do
    binary_nodes = preservation_object.binary_nodes
    file_identifiers = binary_nodes.map(&:file_identifiers)
    file_identifiers.flatten!
  end

  before do
    stub_ezid(shoulder: shoulder, blade: blade)
    persisted_file_set
    change_set = ChangeSet.for(persisted_resource)
    change_set_persister.save(change_set: change_set)
  end

  describe ".new" do
    context "when a storage driver is not passed to the constructor" do
      it "defaults to the Google Cloud storage driver" do
        importer = described_class.new(
          metadata_file_identifier: metadata_file_identifier,
          binary_file_identifiers: binary_file_identifiers,
          change_set_persister: change_set_persister
        )

        expect(importer.storage_adapter).to eq storage_adapter
      end
    end
  end

  describe ".from_preservation_object" do
    it "creates a FileSet with the FileMetadata nodes" do
      imported = described_class.from_preservation_object(
        resource: preservation_object,
        change_set_persister: change_set_persister
      )

      expect(imported).to be_a FileSet
      expect(imported.primary_file.use).to eq [Valkyrie::Vocab::PCDMUse.IntermediateFile]
      expect(imported.optimistic_lock_token).not_to be_empty
      expect(imported.optimistic_lock_token.first).to be_a Valkyrie::Persistence::OptimisticLockToken
      imported_file_metadata = imported.file_metadata
      expect(imported_file_metadata.length).to eq 1
      expect(imported_file_metadata.first.file_identifiers.length).to eq 1
      file_identifier = imported_file_metadata.first.file_identifiers.first
      expect(File.basename(file_identifier.to_s)).to eq File.basename(binary_file_identifiers.first.to_s)
    end

    context "when the preserved resource does not have any metadata" do
      it "creates a FileSet with no imported attributes" do
        new_preservation_object = PreservationObject.new(
          preserved_object_id: preservation_object.preserved_object_id,
          binary_nodes: preservation_object.binary_nodes
        )
        persisted = change_set_persister.metadata_adapter.persister.save(resource: new_preservation_object)

        imported = described_class.from_preservation_object(
          resource: persisted,
          change_set_persister: change_set_persister
        )

        expect(imported).to be_a FileSet
        expect(imported.optimistic_lock_token).not_to be_empty
        expect(imported.optimistic_lock_token.first).to be_a Valkyrie::Persistence::OptimisticLockToken
        imported_file_metadata = imported.file_metadata
        expect(imported_file_metadata).not_to be_empty
        expect(imported.title).to be_empty
      end
    end
  end

  describe "#import!" do
    let(:importer) do
      described_class.new(
        metadata_file_identifier: metadata_file_identifier,
        binary_file_identifiers: binary_file_identifiers,
        change_set_persister: change_set_persister
      )
    end
    let(:imported) { importer.import! }

    it "creates a FileSet with the FileMetadata nodes" do
      expect(imported).to be_a FileSet
      expect(imported.title).to eq ["example.tif"]
      expect(imported.optimistic_lock_token).not_to be_empty
      expect(imported.optimistic_lock_token.first).to be_a Valkyrie::Persistence::OptimisticLockToken
      imported_file_metadata = imported.file_metadata
      expect(imported_file_metadata.length).to eq 1
      expect(imported_file_metadata.first.file_identifiers.length).to eq 1
      file_identifier = imported_file_metadata.first.file_identifiers.first
      expect(File.basename(file_identifier.to_s)).to eq File.basename(binary_file_identifiers.first.to_s)
    end

    context "with an invalid metadata identifier" do
      let(:metadata_file_identifier) { Valkyrie::ID.new("invalid") }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it "creates a FileSet with attributes and logs an error" do
        expect(imported).to be_a FileSet
        expect(imported.optimistic_lock_token).not_to be_empty
        expect(imported.optimistic_lock_token.first).to be_a Valkyrie::Persistence::OptimisticLockToken
        imported_file_metadata = imported.file_metadata
        expect(imported_file_metadata).not_to be_empty
        expect(imported.primary_file.use).to eq [Valkyrie::Vocab::PCDMUse.OriginalFile]
        expect(imported.title).to be_empty
      end
    end

    context "with an invalid binary identifiers" do
      let(:binary_file_identifiers) { [Valkyrie::ID.new("invalid")] }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it "creates a FileSet with no FileMetadata nodes and logs an error" do
        expect(imported).to be_a FileSet
        expect(imported.optimistic_lock_token).not_to be_empty
        expect(imported.optimistic_lock_token.first).to be_a Valkyrie::Persistence::OptimisticLockToken
        imported_file_metadata = imported.file_metadata
        expect(imported_file_metadata).to be_empty
        expect(imported.title).to eq ["example.tif"]
      end
    end
  end
end
