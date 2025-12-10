# frozen_string_literal: true
require "json"

class PreservationCheckJob
  # this job is used with a Sidekiq::Batch, so it needs to be a Sidekiq::Job
  include Sidekiq::Job
  sidekiq_options queue: "super_low"

  # rubocop:disable Style/GuardClause
  def perform(resource_id, audit_id, opts = {})
    resource = query_service.find_by(id: resource_id)

    # if it should't preserve we don't care about it
    return unless ChangeSet.for(resource).preserve?

    if incorrectly_preserved?(resource, prepare_opts(opts))
      PreservationCheckFailure.create(
        preservation_audit_id: audit_id,
        resource_id: resource_id
      )
    end
  end
  # rubocop:enable Style/GuardClause

  def prepare_opts(opts)
    return opts if opts.is_a?(Hash)
    JSON.parse(opts, symbolize_names: true)
  end

  # Preservation object doesn't exist, is missing a metadata or binary node, or the checksums don't match.
  def incorrectly_preserved?(resource, opts)
    preservation_object = Wayfinder.for(resource).preservation_object
    checkers = Preserver::PreservationChecker.for(resource: resource, preservation_object: preservation_object, **opts)
    if preservation_object&.metadata_node.nil?
      true
    elsif checkers.any? { |x| !x.preserved? || !x.preservation_file_exists? || !x.preserved_file_checksums_match? }
      true
    else
      false
    end
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
