# frozen_string_literal: true
require "rails_helper"

RSpec.describe PreservationStatusReporter do
  with_queue_adapter :inline

  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { adapter.query_service }
  let(:disk_preservation_path) { Pathname.new(Figgy.config["disk_preservation_path"]) }

  describe "#cloud_audit", db_cleaner_deletion: true do
    before do
      FileUtils.rm_rf(Rails.root.join("tmp", "audit_state"))
    end
    it "identifies resources that should be preserved and either are not preserved or have the wrong checksum" do
      stub_ezid
      allow(Valkyrie::StorageAdapter.find(:google_cloud_storage)).to receive(:find_by).and_call_original
      # a fileset with a metadata and binary node that are both preserved
      preserved_resource = create_preserved_resource
      # a resource that should not be preserved
      _no_preserving_resource = FactoryBot.create_for_repository(:pending_scanned_resource)
      # a scannedresource with no preservation object
      unpreserved_resource = FactoryBot.create_for_repository(:complete_scanned_resource) # doesn't run change set persister so no preservation will happen
      # a scannedresource with a metadata node that was never preserved
      unpreserved_metadata_resource = create_resource_unpreserved_metadata
      # a fileset with one binary node that is not preserved, but 2 should be
      unpreserved_binary_file_set = create_recording_unpreserved_binary
      # - a scannedresource with a metadata node that has the wrong checksum
      bad_checksum_metadata_resource = create_resource_bad_metadata_checksum
      # - a scannedresource with a metadata node that has the wrong lock token
      bad_lock_token_metadata_resource = create_resource_bad_metadata_lock_token
      # - a fileset with a binary node that has the wrong checksum
      bad_checksum_binary_file_set = create_file_set_bad_binary_checksum
      # - a scannedresource with a metadata node whose file is missing
      missing_metadata_file_resource = create_resource_no_metadata_file
      # - a fileset with a binary node whose file is missing
      missing_binary_file_set = create_file_set_no_binary_file

      # Verify resources have expected faults
      # #preserved resource -- has all files
      expect(File.exist?(disk_preservation_path.join(preserved_resource.id.to_s, "#{preserved_resource.id}.json"))).to eq true
      expect(File.exist?(disk_preservation_path.join(preserved_resource.id.to_s, "data", preserved_resource.member_ids.first.to_s, "#{preserved_resource.member_ids.first}.json"))).to eq true
      file_set = Wayfinder.for(preserved_resource).members.first
      expect(File.exist?(disk_preservation_path.join(preserved_resource.id.to_s, "data", preserved_resource.member_ids.first.to_s, "example-#{file_set.original_file.id}.tif"))).to eq true

      # unpreserved_resource -- missing preservation object
      preservation_object = Wayfinder.for(unpreserved_resource).preservation_objects.first
      expect(preservation_object).to be_nil

      # unpreserved_metadata_resource -- missing metadata node
      preservation_object = Wayfinder.for(unpreserved_metadata_resource).preservation_objects.first
      expect(preservation_object.metadata_node).to be_nil

      # unpreserved_binary_file_set -- missing one binary_node on preservation
      # object
      preservation_object = Wayfinder.for(unpreserved_binary_file_set).preservation_objects.first
      expect(preservation_object.binary_nodes.count).to eq 1

      # run audit
      reporter = described_class.new(suppress_progress: true)
      # Ensure count of resources it's auditing
      expect(reporter.audited_resource_count).to eq 14
      failures = reporter.cloud_audit_failures.to_a
      expect(failures.map(&:id).map(&:to_s)).to contain_exactly(
        unpreserved_resource.id,
        unpreserved_binary_file_set.id,
        unpreserved_metadata_resource.id,
        missing_binary_file_set.id,
        missing_metadata_file_resource.id,
        bad_checksum_metadata_resource.id,
        bad_checksum_binary_file_set.id,
        bad_lock_token_metadata_resource.id
      )
      expect(reporter.progress_bar.progress).to eq 14
    end

    it "can skip checking for bad metadata checksums if requested" do
      stub_ezid
      # - a scannedresource with a metadata node that has the wrong checksum
      create_resource_bad_metadata_checksum

      reporter = described_class.new(suppress_progress: true, skip_metadata_checksum: true)
      # Ensure count of resources it's auditing
      expect(reporter.cloud_audit_failures.to_a.length).to eq 0
    end

    it "can start at a given timestamp and only reprocess those" do
      stub_ezid
      no_preserving_resource = nil
      Timecop.travel(Time.current - 2.days) do
        # a resource that should not be preserved
        FactoryBot.create_for_repository(:pending_scanned_resource)
      end
      Timecop.travel(Time.current - 1.day) do
        no_preserving_resource = FactoryBot.create_for_repository(:pending_scanned_resource)
      end
      # a scannedresource with no preservation object
      _unpreserved_resource = FactoryBot.create_for_repository(:complete_scanned_resource)
      # run audit
      reporter = described_class.new(since: no_preserving_resource.created_at.to_s, suppress_progress: true, records_per_group: 2, parallel_threads: 2)
      reporter.cloud_audit_failures.to_a

      # It re-does the last one at the given date, but not the ones before it.
      expect(reporter.progress_bar.progress).to eq 2
    end

    it "can load a state directory and start where it left off" do
      stub_ezid
      Timecop.travel(Time.current - 2.days) do
        # a resource that should not be preserved
        FactoryBot.create_for_repository(:complete_scanned_resource)
      end
      Timecop.travel(Time.current - 1.day) do
        FactoryBot.create_for_repository(:complete_scanned_resource)
      end
      # a scannedresource with no preservation object
      _unpreserved_resource = FactoryBot.create_for_repository(:complete_scanned_resource)
      # run audit once, break after checking two.
      reporter = described_class.new(suppress_progress: true, records_per_group: 1, parallel_threads: 1)
      reporter.load_state!(state_directory: Rails.root.join("tmp", "audit_state"))
      call_count = 0
      allow(reporter.progress_bar).to receive(:increment) do
        raise "Broken" if call_count == 2
        call_count += 1
      end
      expect { reporter.cloud_audit_failures.to_a }.to raise_error("Broken")
      expect(call_count).to eq 2

      # Run it a second time, it should only load the next two it missed.
      reporter = described_class.new(suppress_progress: true)
      reporter.load_state!(state_directory: Rails.root.join("tmp", "audit_state"))
      output = reporter.cloud_audit_failures.to_a
      # It should merge the previously found resources with the current ones.
      expect(output.length).to eq 3
      expect(reporter.progress_bar.progress).to eq 2
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
