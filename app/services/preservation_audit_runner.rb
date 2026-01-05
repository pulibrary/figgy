# frozen_string_literal: true

# Runs preservation checks as background jobs, grouping failures under a
# PreservationAudit object
class PreservationAuditRunner
  # run an entire audit of all preservable resources
  def self.run(skip_metadata_checksum: false)
    new(skip_metadata_checksum: skip_metadata_checksum).run
  end

  # run a new audit over the failed checks of a given audit
  def self.rerun(skip_metadata_checksum: false, ids_from:)
    new(skip_metadata_checksum: skip_metadata_checksum).rerun(ids_from: ids_from)
  end

  attr_reader :skip_metadata_checksum

  def initialize(skip_metadata_checksum: false)
    @skip_metadata_checksum = skip_metadata_checksum
  end

  def run
    batch = Sidekiq::Batch.new
    audit = PreservationAudit.create(
      status: "in_process",
      extent: "full",
      batch_id: batch.bid
    )
    batch.on(:success, Callbacks, audit_id: audit.id)
    batch.on(:complete, Callbacks, audit_id: audit.id)

    batch.jobs do
      # This only gets IDs and does not instantiate, but if it's too slow
      # we could look at https://github.com/sidekiq/sidekiq/wiki/Batches#huge-batches
      all_ids.each_slice(1000) do |ids|
        push_check_jobs(ids, audit.id)
      end
    end
  end

  def rerun(ids_from:)
    batch = Sidekiq::Batch.new
    audit = PreservationAudit.create(
      status: "in_process",
      extent: "partial",
      ids_from: ids_from,
      batch_id: batch.bid
    )
    batch.on(:success, Callbacks, audit_id: audit.id)
    batch.on(:complete, Callbacks, audit_id: audit.id)

    batch.jobs do
      rerun_ids(ids_from).each_slice(1000) do |ids|
        push_check_jobs(ids, audit.id)
      end
    end
  end

  private

    def push_check_jobs(ids, audit_id)
      # push in bulk; reduces round trips to redis and keeps it from timing out
      # @see https://github.com/sidekiq/sidekiq/wiki/Bulk-Queueing
      Sidekiq::Client.push_bulk(
        "class" => PreservationCheckJob,
        "args" => ids.map { |id| [id, audit_id, job_opts] }
      )
    end

    def all_ids
      query_service.custom_queries.all_ids(except_models: unpreserved_models)
    end

    def rerun_ids(ids_from)
      ids_from.preservation_check_failures.map(&:resource_id)
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
