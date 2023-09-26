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
      # Test setup required:
      #  - preserved_resource: a fileset with a metadata and binary node that are both preserved
      #  - unpreserved_metadata_resource: a scannedresource with a metadata node that was never preserved
      #  - a fileset with a binary node that is not preserved
      #  - a fileset with both metadata and a binary nodes that are not preserved
      #  - a scannedresource with a metadata node that has the wrong checksum
      #  - a fileset with a binary node that has the wrong checksum
      stub_ezid
      preserved_resource = create_preserved_resource
      unpreserved_metadata_resource = FactoryBot.create_for_repository(:complete_scanned_resource) # doesn't run change set persister so no preservation will happen
      recording = FactoryBot.create_for_repository(:complete_recording_with_real_files)
      recording_file_set = Wayfinder.for(recording).file_sets.first
      intermediate_file = recording_file_set.intermediate_file
      fs_po = Wayfinder.for(recording_file_set).preservation_objects.first
      fs_po.binary_nodes = fs_po.binary_nodes.find { |node| node.preservation_copy_of_id != intermediate_file.id}
      ruined_po = ChangeSetPersister.default.save(change_set: ChangeSet.for(fs_po))

      # Verify files exist or not
      # #preserved resource files
      expect(File.exist?(disk_preservation_path.join(preserved_resource.id.to_s, "#{preserved_resource.id}.json"))).to eq true
      expect(File.exist?(disk_preservation_path.join(preserved_resource.id.to_s, "data", preserved_resource.member_ids.first.to_s, "#{preserved_resource.member_ids.first}.json"))).to eq true
      file_set = Wayfinder.for(preserved_resource).members.first
      expect(File.exist?(disk_preservation_path.join(preserved_resource.id.to_s, "data", preserved_resource.member_ids.first.to_s, "example-#{file_set.original_file.id}.tif"))).to eq true

      # unpreserved_metadata_resource files
      expect(File.exist?(disk_preservation_path.join(unpreserved_metadata_resource.id.to_s, "#{unpreserved_metadata_resource.id}.json"))).to eq false

      # run audit
      reporter = described_class.new(progress_bar: false)
      failures = reporter.cloud_audit_failures
      expect(failures.map(&:id)).to contain_exactly(
        unpreserved_metadata_resource.id,
        recording_file_set.id
      )
    end
  end

  def create_preserved_resource
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
    reloaded_resource = query_service.find_by(id: resource.id)
    change_set = ChangeSet.for(reloaded_resource)
    output = change_set_persister.save(change_set: change_set)
  end
end
