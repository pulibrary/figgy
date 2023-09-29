# frozen_string_literal: true
require "rails_helper"

RSpec.describe PreservationStatusReporter do
  with_queue_adapter :inline

  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { adapter.query_service }
  let(:disk_preservation_path) { Pathname.new(Figgy.config["disk_preservation_path"]) }

  describe "#cloud_audit" do
    it "identifies resources that should be preserved and either are not preserved or have the wrong checksum" do
      stub_ezid
      # a fileset with a metadata and binary node that are both preserved
      preserved_resource = create_preserved_resource
      # a scannedresource with no preservation object
      unpreserved_resource = FactoryBot.create_for_repository(:complete_scanned_resource) # doesn't run change set persister so no preservation will happen
      # a scannedresource with a metadata node that was never preserved
      unpreserved_metadata_resource = create_resource_unpreserved_metadata
      # a fileset with one binary node that is not preserved, but 2 should be
      unpreserved_binary_file_set = create_recording_unpreserved_binary
      # - a scannedresource with a metadata node that has the wrong checksum
      bad_checksum_metadata_resource = create_resource_bad_metadata_checksum
      # - a fileset with a binary node that has the wrong checksum
      bad_checksum_binary_file_set = create_file_set_bad_binary_checksum
      # - a scannedresource with a metadata node whose file is missing
      missing_metadata_file_resource =  create_resource_no_metadata_file
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
      reporter = described_class.new(progress_bar: false)
      failures = reporter.cloud_audit_failures
      expect(failures.map(&:id)).to contain_exactly(
        unpreserved_resource.id,
        unpreserved_binary_file_set.id,
        unpreserved_metadata_resource.id,
        # bad_checksum_metadata_resource.id
      )
    end
    # TODO: add these in one at a time
    # bad_checksum_binary_file_set.id
    # missing_metadata_file_resource.id
    # missing_binary_file_set.id
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
