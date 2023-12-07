# frozen_string_literal: true
require "rails_helper"

RSpec.describe PreservationStatusIdChecker do
  with_queue_adapter :inline

  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { adapter.query_service }
  let(:disk_preservation_path) { Pathname.new(Figgy.config["disk_preservation_path"]) }

  describe "#cloud_audit", db_cleaner_deletion: true do
    context "with a CSV that contains resource IDs" do
      let(:state_directory) { Rails.root.join("tmp", "preservation_status_id_checker_spec") }
      after do
        FileUtils.rm_rf(Rails.root.join(state_directory))
      end

      it "can take a path to the CSV as a parameter and will only check those resources" do
        stub_ezid
        FileUtils.mkdir_p(state_directory)
        allow(Valkyrie::StorageAdapter.find(:google_cloud_storage)).to receive(:find_by).and_call_original
        preserved_resource = create_preserved_resource
        unpreserved_resource = FactoryBot.create_for_repository(:complete_scanned_resource)
        unpreserved_metadata_resource = create_resource_unpreserved_metadata
        # resource not included in CSV
        create_recording_unpreserved_binary

        # build CSV
        build_csv_file(
          dir: state_directory,
          values: [
            preserved_resource.id.to_s,
            unpreserved_resource.id.to_s,
            unpreserved_metadata_resource.id.to_s
          ]
        )

        # run audit
        reporter = described_class.new(suppress_progress: true)
        reporter.load_state!(state_directory: state_directory)
        # Ensure count of resources it's auditing
        expect(reporter.audited_resource_count).to eq 3

        failures = reporter.cloud_audit_failures.to_a
        expect(failures.map(&:id).map(&:to_s)).to contain_exactly(
          unpreserved_resource.id,
          unpreserved_metadata_resource.id
        )
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

  def create_recording_unpreserved_binary
    recording = FactoryBot.create_for_repository(:complete_recording_with_real_files)
    recording_file_set = Wayfinder.for(recording).file_sets.first
    intermediate_file = recording_file_set.intermediate_file
    fs_po = Wayfinder.for(recording_file_set).preservation_objects.first
    fs_po.binary_nodes = fs_po.binary_nodes.find { |node| node.preservation_copy_of_id != intermediate_file.id }
    ChangeSetPersister.default.save(change_set: ChangeSet.for(fs_po))
    recording_file_set
  end

  def build_csv_file(dir:, values:)
    CSV.open(Rails.root.join(dir, "bad_resources.txt"), "w") do |csv|
      values.each { |value| csv << [value] }
    end
  end
end
