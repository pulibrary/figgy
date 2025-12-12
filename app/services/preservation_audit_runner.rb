# frozen_string_literal: true

# Runs preservation checks as background jobs, grouping failures under a
# PreservationAudit object
class PreservationAuditRunner
  # run an entire audit of all preservable resources
  def self.run(skip_metadata_checksum: false)
    new(skip_metadata_checksum: skip_metadata_checksum).run
  end

  # run a new audit over the failed checks of a given audit
  def self.rerun(audit)
    new(rerun_audit: audit).run
  end

  attr_reader :skip_metadata_checksum, :rerun_audit

  def initialize(skip_metadata_checksum: false, rerun_audit: nil)
    @skip_metadata_checksum = skip_metadata_checksum
    @rerun_audit = rerun_audit
  end

  def run
    batch = Sidekiq::Batch.new
    audit = PreservationAudit.create(
      status: "in_process",
      extent: determine_extent,
      batch_id: batch.bid
    )
    batch.on(:success, Callbacks, audit_id: audit.id)
    batch.jobs do
      # TODO: think about sending these in slices to another job that adds the jobs
      ids.each do |id|
        PreservationCheckJob.perform_async(id, audit.id, job_opts)
      end
    end
  end

  private

    def determine_extent
      if @rerun_audit
        "partial"
      else
        "full"
      end
    end

    def ids
      if @rerun_audit
        @rerun_audit.preservation_check_failures.map(&:resource_id)
      else
        query_service.custom_queries.all_ids(except_models: unpreserved_models)
      end
    end

    def job_opts
      @job_opts ||= {}.tap do |h|
        h[:skip_metadata_checksum] = true if @skip_metadata_checksum
      end.to_json
    end

    def unpreserved_models
      [
        DeletionMarker,
        Event,
        PreservationObject,
        CDL::ResourceChargeList
      ]
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    class Callbacks
      def on_success(_status, options)
        audit = PreservationAudit.find(options["audit_id"])
        failure_count = audit.preservation_check_failures.count
        case failure_count
        when 0
          audit.status = "success"
          audit.save
          PreservationAuditMailer.with(audit: audit).success.deliver_later
        else
          audit.status = "failure"
          audit.save
          PreservationAuditMailer.with(audit: audit, failure_count: failure_count).failure.deliver_later
        end
      end
    end
end
