# frozen_string_literal: true
require "rails_helper"
require "support/preserved_objects"

RSpec.describe PreservationAuditRunner do
  with_queue_adapter :inline

  describe ".run" do
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
      expect(PreservationAudit.count).to eq 2
      expect(PreservationAudit.all.map(&:extent)).to contain_exactly("full", "partial")
      # the new audit holds a link to the previous audit
      rerun = PreservationAudit.find_by(extent: "partial")
      expect(rerun.ids_from).to eq audit
    end
  end

  describe "Callbacks.success" do
    Sidekiq::Testing.server_middleware.add Sidekiq::Batch::Server
    context "when there are no failures on the audit" do
      it "updates audit status and emails success message to the libanswers queue" do
        stub_ezid
        create_preserved_resource

        Sidekiq::Testing.inline! do
          described_class.run
        end

        audit = PreservationAudit.last

        expect(audit.status).to eq "success"
        expect(ActionMailer::Base.deliveries.size).to eq 1
        expect(ActionMailer::Base.deliveries.first.subject).to eq "Preservation audit successful"
        expect(ActionMailer::Base.deliveries.first.html_part.body.decoded).to match("No preservation failures were found")
      end
    end

    # TODO: initiate retries
    context "when there are failures on the audit" do
      it "updates audit status and emails failure message to the libanswers queue" do
        stub_ezid
        create_resource_unpreserved_metadata

        Sidekiq::Testing.inline! do
          described_class.run
        end

        audit = PreservationAudit.last

        expect(audit.status).to eq "failure"
        expect(ActionMailer::Base.deliveries.size).to eq 1
        expect(ActionMailer::Base.deliveries.first.subject).to eq "Preservation audit found failures"
        expect(ActionMailer::Base.deliveries.first.html_part.body.decoded).to match(
          "Preservation Audit batch completed and all jobs ran. 1 preservation failures were found. 0 of 3 retries have been run on this audit."
        )
      end
    end
  end

  describe "Callbacks.complete" do
    it "updates audit status and emails the libanswers queue" do
      stub_ezid
      resource = create_resource_bad_metadata_checksum
      batch = Sidekiq::Batch.new
      audit = PreservationAudit.create(
        status: "in_process",
        extent: "full",
        batch_id: batch.bid
      )
      batch.on(:complete, PreservationAuditRunner::Callbacks, audit_id: audit.id)

      batch.jobs do
        PreservationCheckJob.perform_async(resource.id.to_s, audit.id)
      end

      PreservationAuditRunner::Callbacks.new.on_complete(
        Sidekiq::Batch::Status.new(batch.bid),
        { "audit_id" => audit.id }
      )

      expect(audit.reload.status).to eq "complete"
      expect(ActionMailer::Base.deliveries.size).to eq 1
      expect(ActionMailer::Base.deliveries.first.subject).to eq "Preservation audit: all jobs have run once"
      expect(ActionMailer::Base.deliveries.first.html_part.body.decoded).to match(
        "Preservation Audit batch is complete, but some jobs failed."
      )
    end
  end

  describe "Callbacks.death" do
    it "updates audit status and emails the libanswers queue" do
      stub_ezid
      resource = create_resource_bad_metadata_checksum
      batch = Sidekiq::Batch.new
      audit = PreservationAudit.create(
        status: "in_process",
        extent: "full",
        batch_id: batch.bid
      )
      batch.on(:death, PreservationAuditRunner::Callbacks, audit_id: audit.id)

      batch.jobs do
        PreservationCheckJob.perform_async(resource.id.to_s, audit.id)
      end

      PreservationAuditRunner::Callbacks.new.on_death(
        Sidekiq::Batch::Status.new(batch.bid),
        { "audit_id" => audit.id }
      )

      expect(audit.reload.status).to eq "dead"
      expect(ActionMailer::Base.deliveries.size).to eq 1
      expect(ActionMailer::Base.deliveries.first.subject).to eq "Preservation audit: dead queue"
      expect(ActionMailer::Base.deliveries.first.html_part.body.decoded).to match(
        "At least one job from the Preservation Audit batch has been moved to the dead queue."
      )
    end
  end
end
