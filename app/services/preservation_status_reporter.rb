# frozen_string_literal: true

# Checks every resource in the database. If it should be preserved, then checks
# that all its files and its metadata are preserved and have the correct
# MD5 checksums.
# Future use case: We'll get this to where it returns nothing. If down the road
# it returns something again, we'll want more details about what / why it's
# failing.
require "ruby-progressbar"
require "ruby-progressbar/outputs/null"
class PreservationStatusReporter
  attr_reader :since, :suppress_progress, :records_per_group, :parallel_threads, :skip_metadata_checksum
  def initialize(since: nil, suppress_progress: false, records_per_group: 100, parallel_threads: 10, skip_metadata_checksum: false)
    @since = since
    @suppress_progress = suppress_progress
    @records_per_group = records_per_group
    @parallel_threads = parallel_threads
    @found_resources = Set.new
    @skip_metadata_checksum = skip_metadata_checksum
  end

  # @return [Array<Valkyrie::ID>]
  def cloud_audit_failures
    @cloud_audit_failures ||= Lazily.concat(@found_resources, run_cloud_audit).uniq
  end

  def audited_resource_count
    query_service.custom_queries.count_all_except_models(except_models: unpreserved_models, since: since)
  end

  # @return [Array<Valkyrie::ID>] a lazy enumerator
  def run_cloud_audit
    query_service.custom_queries.memory_efficient_all(except_models: unpreserved_models, order: true, since: since).each_slice(records_per_group).lazily.in_threads(parallel_threads) do |resources|
      bad_resources = resources.select do |resource|
        progress_bar.increment
        # if it should't preserve we don't care about it
        next unless ChangeSet.for(resource).preserve?
        incorrectly_preserved?(resource)
      end.map(&:id)
      # At the end of every batch save which resources were found and the last
      # one checked.
      bad_resources.tap do |selected_resources|
        processed(last_checked: resources.last, bad_resource_ids: selected_resources.map(&:to_s))
      end
    end.flatten
  end

  # Preservation object doesn't exist, is missing a metadata or binary node, or the checksums don't match.
  def incorrectly_preserved?(resource)
    preservation_object = Wayfinder.for(resource).preservation_object
    checkers = Preserver::PreservationChecker.for(resource: resource, preservation_object: preservation_object, skip_metadata_checksum: skip_metadata_checksum)
    if preservation_object&.metadata_node.nil?
      true
    elsif checkers.any? { |x| !x.preserved? || !x.preservation_file_exists? || !x.preserved_file_checksums_match? }
      true
    else
      false
    end
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

  # Progress bar stuff
  def progress_bar
    @progress_bar ||= ProgressBar.create format: "%a %e %P% Querying: %c from %C", output: progress_output, total: audited_resource_count
  end

  def progress_output
    ProgressBar::Outputs::Null if suppress_progress
  end

  # State Management
  def load_state!(state_directory:)
    state_directory = Pathname.new(state_directory)
    FileUtils.mkdir_p(state_directory)
    @state_file_path = state_directory.join("since.txt")
    @since = @state_file_path.read if @state_file_path.exist?
    @found_resource_path = state_directory.join("bad_resources.txt")
    @found_resources = Set.new(@found_resource_path.read.split.map { |x| Valkyrie::ID.new(x) }) if @found_resource_path.exist?
  end

  def processed(last_checked:, bad_resource_ids:)
    return unless @state_file_path
    File.open(@state_file_path, "w") do |f|
      f.write(last_checked.created_at.to_s)
    end
    File.open(@found_resource_path, "a") do |f|
      bad_resource_ids.each do |resource_id|
        f.puts resource_id
      end
    end
  end
end
