# frozen_string_literal: true
require "rails_helper"

RSpec.describe PreservationCheckJob do
  with_queue_adapter :inline

  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { change_set_persister.query_service }
  let(:disk_preservation_path) { Pathname.new(Figgy.config["disk_preservation_path"]) }

  describe "#perform" do
    let(:audit) { FactoryBot.create(:preservation_audit) }

    before do
      stub_ezid
      allow(Valkyrie::StorageAdapter.find(:google_cloud_storage)).to receive(:find_by).and_call_original
    end

    context "with a fileset with a metadata and binary node that are both preserved" do
      it "does not write a PreservationCheckFailure" do
        preserved_resource = create_preserved_resource
        # Verify preserved resource has all files
        expect(File.exist?(disk_preservation_path.join(preserved_resource.id.to_s, "#{preserved_resource.id}.json"))).to eq true
        expect(File.exist?(disk_preservation_path.join(preserved_resource.id.to_s, "data", preserved_resource.member_ids.first.to_s, "#{preserved_resource.member_ids.first}.json"))).to eq true
        file_set = Wayfinder.for(preserved_resource).members.first
        expect(File.exist?(disk_preservation_path.join(preserved_resource.id.to_s, "data", preserved_resource.member_ids.first.to_s, "example-#{file_set.original_file.id}.tif"))).to eq true

        described_class.new.perform(preserved_resource.id, audit.id)

        expect(PreservationCheckFailure.count).to eq 0
      end
    end

    context "with a resource that should not be preserved" do
      it "does not write a PreservationCheckFailure" do
        no_preserving_resource = FactoryBot.create_for_repository(:pending_scanned_resource)

        described_class.new.perform(no_preserving_resource.id, audit.id)

        expect(PreservationCheckFailure.count).to eq 0
      end
    end

    context "with a scannedresource with no preservation object" do
      it "writes a PreservationCheckFailure" do
        # doesn't run change set persister so no preservation will happen
        unpreserved_resource = FactoryBot.create_for_repository(:complete_scanned_resource)
        # missing preservation object
        preservation_object = Wayfinder.for(unpreserved_resource).preservation_objects.first
        expect(preservation_object).to be_nil

        described_class.new.perform(unpreserved_resource.id, audit.id)

        expect(PreservationCheckFailure.count).to eq 1
        expect(PreservationCheckFailure.first.resource_id).to eq unpreserved_resource.id
      end
    end

    context "with a scannedresource with a metadata node that was never preserved" do
      it "writes a PreservationCheckFailure" do
        unpreserved_metadata_resource = create_resource_unpreserved_metadata
        preservation_object = Wayfinder.for(unpreserved_metadata_resource).preservation_objects.first
        expect(preservation_object.metadata_node).to be_nil

        described_class.new.perform(unpreserved_metadata_resource.id, audit.id)

        expect(PreservationCheckFailure.count).to eq 1
        expect(PreservationCheckFailure.first.resource_id).to eq unpreserved_metadata_resource.id
      end
    end

    context "with a fileset with one binary node that is not preserved, but 2 should be" do
      it "writes a PreservationCheckFailure" do
        unpreserved_binary_file_set = create_recording_unpreserved_binary
        preservation_object = Wayfinder.for(unpreserved_binary_file_set).preservation_objects.first
        expect(preservation_object.binary_nodes.count).to eq 1

        described_class.new.perform(unpreserved_binary_file_set.id, audit.id)

        expect(PreservationCheckFailure.count).to eq 1
        expect(PreservationCheckFailure.first.resource_id).to eq unpreserved_binary_file_set.id
      end
    end

    context "with a scannedresource with a metadata node that has the wrong checksum" do
      it "writes a PreservationCheckFailure" do
        bad_checksum_metadata_resource = create_resource_bad_metadata_checksum

        described_class.new.perform(bad_checksum_metadata_resource.id, audit.id)

        expect(PreservationCheckFailure.count).to eq 1
        expect(PreservationCheckFailure.first.resource_id).to eq bad_checksum_metadata_resource.id
      end
    end

    context "with a scannedresource with a metadata node that has the wrong lock token" do
      it "writes a PreservationCheckFailure" do
        bad_lock_token_metadata_resource = create_resource_bad_metadata_lock_token

        described_class.new.perform(bad_lock_token_metadata_resource.id, audit.id)

        expect(PreservationCheckFailure.count).to eq 1
        expect(PreservationCheckFailure.first.resource_id).to eq bad_lock_token_metadata_resource.id
      end
    end

    context "with a fileset with a binary node that has the wrong checksum" do
      it "writes a PreservationCheckFailure" do
        bad_checksum_binary_file_set = create_file_set_bad_binary_checksum

        described_class.new.perform(bad_checksum_binary_file_set.id, audit.id)

        expect(PreservationCheckFailure.count).to eq 1
        expect(PreservationCheckFailure.first.resource_id).to eq bad_checksum_binary_file_set.id
      end
    end

    context "with a scannedresource with a metadata node whose file is missing" do
      it "writes a PreservationCheckFailure" do
        missing_metadata_file_resource = create_resource_no_metadata_file

        described_class.new.perform(missing_metadata_file_resource.id, audit.id)

        expect(PreservationCheckFailure.count).to eq 1
        expect(PreservationCheckFailure.first.resource_id).to eq missing_metadata_file_resource.id
      end
    end

    context "with a fileset with a binary node whose file is missing" do
      it "writes a PreservationCheckFailure" do
        missing_binary_file_set = create_file_set_no_binary_file

        described_class.new.perform(missing_binary_file_set.id, audit.id)

        expect(PreservationCheckFailure.count).to eq 1
        expect(PreservationCheckFailure.first.resource_id).to eq missing_binary_file_set.id
      end
    end
  end

  def create_preserved_resource
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
    reloaded_resource = query_service.find_by(id: resource.id)
    change_set = ChangeSet.for(reloaded_resource)
    change_set_persister.save(change_set: change_set)
  end

  def create_resource_unpreserved_metadata
    resource = FactoryBot.create_for_repository(:complete_scanned_resource)
    reloaded_resource = query_service.find_by(id: resource.id)
    change_set = ChangeSet.for(reloaded_resource)
    resource = change_set_persister.save(change_set: change_set)
    po = Wayfinder.for(resource).preservation_objects.first
    po.metadata_node = nil
    ChangeSetPersister.default.save(change_set: ChangeSet.for(po))
    resource
  end

  def create_file_set_bad_binary_checksum
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
    reloaded_resource = query_service.find_by(id: resource.id)
    change_set = ChangeSet.for(reloaded_resource)
    resource = change_set_persister.save(change_set: change_set)
    file_set = Wayfinder.for(resource).file_sets.first
    po = Wayfinder.for(file_set).preservation_objects.first
    modify_file(po.binary_nodes.first.file_identifiers.first)
    file_set
  end

  def create_resource_bad_metadata_checksum
    resource = FactoryBot.create_for_repository(:complete_scanned_resource)
    reloaded_resource = query_service.find_by(id: resource.id)
    change_set = ChangeSet.for(reloaded_resource)
    resource = change_set_persister.save(change_set: change_set)
    po = Wayfinder.for(resource).preservation_objects.first
    modify_file(po.metadata_node.file_identifiers.first)
    resource
  end

  def create_resource_bad_metadata_lock_token
    resource = FactoryBot.create_for_repository(:complete_scanned_resource)
    reloaded_resource = query_service.find_by(id: resource.id)
    change_set = ChangeSet.for(reloaded_resource)
    resource = change_set_persister.save(change_set: change_set)
    po = Wayfinder.for(resource).preservation_objects.first
    po.metadata_version = "6"
    ChangeSetPersister.default.metadata_adapter.persister.save(resource: po)
    resource
  end

  def create_resource_no_metadata_file
    resource = FactoryBot.create_for_repository(:complete_scanned_resource)
    reloaded_resource = query_service.find_by(id: resource.id)
    change_set = ChangeSet.for(reloaded_resource)
    resource = change_set_persister.save(change_set: change_set)
    po = Wayfinder.for(resource).preservation_objects.first
    path = po.metadata_node.file_identifiers.first.to_s.gsub("disk://", "")
    FileUtils.rm(path)
    resource
  end

  def create_file_set_no_binary_file
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
    reloaded_resource = query_service.find_by(id: resource.id)
    change_set = ChangeSet.for(reloaded_resource)
    resource = change_set_persister.save(change_set: change_set)
    file_set = Wayfinder.for(resource).file_sets.first
    po = Wayfinder.for(file_set).preservation_objects.first
    path = po.binary_nodes.first.file_identifiers.first.to_s.gsub("disk://", "")
    FileUtils.rm(path)
    file_set
  end

  def create_recording_unpreserved_binary
    recording = FactoryBot.create_for_repository(:complete_recording_with_real_files)
    recording_file_set = Wayfinder.for(recording).file_sets.first
    intermediate_file = recording_file_set.intermediate_file
    fs_po = Wayfinder.for(recording_file_set).preservation_objects.first
    fs_po.binary_nodes = fs_po.binary_nodes.find { |node| node.preservation_copy_of_id != intermediate_file.id }
    ChangeSetPersister.default.save(change_set: ChangeSet.for(fs_po))
    recording_file_set
  end
end
