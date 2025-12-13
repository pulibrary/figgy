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
    new(ids_from: audit).run
  end

  attr_reader :skip_metadata_checksum, :ids_from

  def initialize(skip_metadata_checksum: false, ids_from: nil)
    @skip_metadata_checksum = skip_metadata_checksum
    @ids_from = ids_from
  end

  def run
    batch = Sidekiq::Batch.new
    audit = PreservationAudit.create(
      status: "in_process",
      extent: determine_extent,
      batch_id: batch.bid,
      ids_from: ids_from
    )
    batch.on(:success, Callbacks, audit_id: audit.id)
    batch.on(:complete, Callbacks, audit_id: audit.id)
    batch.jobs do
      # TODO: think about sending these in slices to another job that adds the jobs
      ids.each do |id|
        PreservationCheckJob.perform_async(id, audit.id, job_opts)
      end
    end
  end

  private

    def determine_extent
      if @ids_from
        "partial"
      else
        "full"
      end
    end

    def ids
      if @ids_from
        @ids_from.preservation_check_failures.map(&:resource_id)
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

      def on_complete(status, options)
        # if it was successful, it'll run the success callback and we don't want both
        return if status.callbacks.keys.include?("success")
        audit = PreservationAudit.find(options["audit_id"])
        audit.status = "complete"
        audit.save
        PreservationAuditMailer.with(audit: audit).complete.deliver_later
      end

      def on_death(_status, options)
        audit = PreservationAudit.find(options["audit_id"])
        audit.status = "dead"
        audit.save
        PreservationAuditMailer.with(audit: audit).dead.deliver_later
      end
    end
end
