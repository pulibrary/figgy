# Runs preservation checks as background jobs, grouping failures under a
# PreservationAudit object
class PreservationAuditRunner
  # run an entire audit of all preservable resources
  def self.run(skip_metadata_checksum: false)
    new(skip_metadata_checksum: skip_metadata_checksum).run
  end

  # run a new audit over the failed checks of a given audit
  def self.rerun(ids_from:)
    new.rerun(ids_from: ids_from)
  end

  BATCH_SIZE = 1000
  UNPRESERVED_MODELS = [
    DeletionMarker,
    Event,
    PreservationObject,
    CDL::ResourceChargeList
  ].freeze

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

    count = query_service.custom_queries.count_all_except_models(except_models: UNPRESERVED_MODELS)
    n = count.ceildiv(BATCH_SIZE)

    batch.jobs do
      n.times do |idx|
        Loader.perform_async(idx, audit.id, job_opts)
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
      rerun_ids(ids_from).each_slice(BATCH_SIZE) do |ids|
        push_check_jobs(ids, audit.id)
      end
    end
  end

  private

    def rerun_ids(ids_from)
      ids_from.preservation_check_failures.map(&:resource_id)
    end

    def push_check_jobs(ids, audit_id)
      # push in bulk; reduces round trips to redis and keeps it from timing out
      # @see https://github.com/sidekiq/sidekiq/wiki/Bulk-Queueing
      Sidekiq::Client.push_bulk(
        "class" => PreservationCheckJob,
        "args" => ids.map { |id| [id, audit_id, job_opts] }
      )
    end

    def job_opts
      @job_opts ||= {}.tap do |h|
        h[:skip_metadata_checksum] = true if @skip_metadata_checksum
      end.to_json
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

    # This Job adds the actual jobs we're trying to run into the batch.
    # Parallelizing job load allows us to avoid redit timeouts.
    class Loader
      include Sidekiq::Job
      sidekiq_options queue: "super_low"

      def perform(idx, audit_id, job_opts)
        query_service = Valkyrie.config.metadata_adapter.query_service
        id_slice = query_service.custom_queries.all_ids(
          except_models: UNPRESERVED_MODELS,
          limit_offset_tuple: [BATCH_SIZE, idx * BATCH_SIZE]
        )

        batch.jobs do
          Sidekiq::Client.push_bulk(
            "class" => PreservationCheckJob,
            "args" => id_slice.map { |id| [id, audit_id, job_opts] }
          )
        end
      end
    end
end
