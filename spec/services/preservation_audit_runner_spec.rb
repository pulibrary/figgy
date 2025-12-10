# frozen_string_literal: true
require "rails_helper"

RSpec.describe PreservationAuditRunner do
  with_queue_adapter :inline
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { change_set_persister.query_service }

  describe "#run" do
    it "creates a PreservationAudit with PreservationCheckFailure" do
      stub_ezid
      create_preserved_resource
      unpreserved_metadata_resource = create_resource_unpreserved_metadata

      Sidekiq::Testing.inline! do
        described_class.run

        audit = PreservationAudit.last

        expect(audit.preservation_check_failures.map(&:resource_id)).to eq [unpreserved_metadata_resource.id]
      end
    end

    it "does not initiate the check job for an unpreserved model" do
      FactoryBot.create_for_repository(:event)
      FactoryBot.create_for_repository(:scanned_resource)

      expect { described_class.run }.to change(PreservationCheckJob.jobs, :size).by(1)
    end

    it "enqueues jobs to super_low" do
      FactoryBot.create_for_repository(:scanned_resource)

      described_class.run

      expect(Sidekiq::Queues["super_low"].size).to eq 1
    end
  end

  it "can skip checking for bad metadata checksums if requested" do
    stub_ezid
    create_resource_bad_metadata_checksum

    Sidekiq::Testing.inline! do
      described_class.run(skip_metadata_checksum: true)

      audit = PreservationAudit.last

      expect(audit.preservation_check_failures).to be_empty
    end
  end

  describe "#rerun" do
    it "uses only the ids from the PreservationCheckFailures on the given audit" do
      stub_ezid
      # this resource won't be checked by the rerun
      create_preserved_resource
      unpreserved_metadata_resource = create_resource_unpreserved_metadata

      audit = FactoryBot.create(
        :preservation_audit,
        status: "in_process",
        extent: "full",
        batch_id: "bc7f822afbb40747"
      )
      FactoryBot.create(:preservation_check_failure, resource_id: unpreserved_metadata_resource.id, preservation_audit: audit)

      expect { described_class.rerun(audit) }.to change(PreservationCheckJob.jobs, :size).by(1)
      # TODO: the rerun should have a link to the audit it's rerunning
      expect(PreservationAudit.all.map(&:extent)).to contain_exactly("full", "partial")
    end
  end

  # TODO: test audit status values get set as desired

  # TODO: run with initial batch_id, i.e. run using only the failures from a
  # previous audit

  # TODO: retries if any jobs errored
  # it "retries file fetch if there's an ssl error for a metadata file" do
  #   stub_ezid
  #   # - a scannedresource with a metadata node that has the wrong checksum
  #   resource = create_resource_bad_metadata_checksum
  #   # error the first time, but not subsequent times
  #   values = [proc { raise OpenSSL::SSL::SSLError }]
  #   # Binary is fine
  #   allow(Valkyrie::StorageAdapter.find(:google_cloud_storage))
  #     .to receive(:find_by)
  #     .and_call_original
  #   # metadata errors
  #   allow(Valkyrie::StorageAdapter.find(:google_cloud_storage))
  #     .to receive(:find_by)
  #     .with(id: Wayfinder.for(resource).preservation_objects.first.metadata_node.file_identifiers.first)
  #     .and_wrap_original do |original, **args|
  #     values.empty? ? original.call(**args) : values.shift.call
  #   end
  #
  #   reporter = described_class.new(suppress_progress: true, io_directory: io_dir)
  #   expect(reporter.cloud_audit_failures.to_a.map(&:id)).to eq([resource.id])
  # end

  # TODO: emails us if the batch succeeded

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

  def create_resource_bad_metadata_checksum
    resource = FactoryBot.create_for_repository(:complete_scanned_resource)
    reloaded_resource = query_service.find_by(id: resource.id)
    change_set = ChangeSet.for(reloaded_resource)
    resource = change_set_persister.save(change_set: change_set)
    po = Wayfinder.for(resource).preservation_objects.first
    modify_file(po.metadata_node.file_identifiers.first)
    resource
  end
end
