# frozen_string_literal: true

# Checks resource preservation status. If it should be preserved, then checks
# that all its files and its metadata are preserved and have the correct
# MD5 checksums.
# Future use case: We'll get this to where it returns nothing. If down the road
# it returns something again, we'll want more details about what / why it's
# failing.
require "ruby-progressbar"
require "ruby-progressbar/outputs/null"

# rubocop:disable Metrics/ClassLength
class PreservationStatusReporter
  # Check all resources with resumable state
  def self.run_full_audit(io_directory:)
    new(io_directory: io_directory).cloud_audit_failures
  end

  # Check resources by id, using the list output in the full audit
  def self.run_recheck(io_directory:)
    new(io_directory: io_directory, recheck_ids: true).cloud_audit_failures
  end

  attr_reader :since, :suppress_progress, :records_per_group, :parallel_threads, :skip_metadata_checksum, :io_directory, :recheck_ids

  # rubocop:disable Metrics/ParameterLists
  def initialize(suppress_progress: false, records_per_group: 100, parallel_threads: 10, skip_metadata_checksum: false, io_directory:, recheck_ids: false)
    @suppress_progress = suppress_progress
    @records_per_group = records_per_group
    @parallel_threads = parallel_threads
    @found_resources = Set.new
    @skip_metadata_checksum = skip_metadata_checksum
    @recheck_ids = recheck_ids
    initialize_io_directory(io_directory)
  end
  # rubocop:enable Metrics/ParameterLists

  # @return [Array<Valkyrie::ID>]
  def cloud_audit_failures
    @cloud_audit_failures ||= Lazily.concat(@found_resources, run_cloud_audit).uniq
  end

  # @return [Array<Valkyrie::ID>] a lazy enumerator
  def run_cloud_audit
    resource_query.each_slice(records_per_group).lazily.in_threads(parallel_threads) do |resources|
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

  def audited_resource_count
    if recheck_ids
      ids_from_csv.count
    else
      query_service.custom_queries.count_all_except_models(except_models: unpreserved_models, since: since)
    end
  end

  # Progress bar stuff
  def progress_bar
    @progress_bar ||= ProgressBar.create format: "%a %e %P% Querying: %c from %C", output: progress_output, total: audited_resource_count
  end

  def full_audit_output_file
    "bad_resources.txt"
  end

  def recheck_output_file
    "bad_resources_recheck.txt"
  end

  private

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

    def progress_output
      ProgressBar::Outputs::Null if suppress_progress
    end

    def processed(last_checked:, bad_resource_ids:)
      unless recheck_ids
        File.open(@timestamp_file_path, "w") do |f|
          f.write(last_checked.created_at.to_s)
        end
      end
      File.open(@found_resource_path, "a") do |f|
        bad_resource_ids.each do |resource_id|
          f.puts resource_id
        end
      end
    end

    def initialize_io_directory(io_directory)
      @io_directory = Pathname.new(io_directory)
      FileUtils.mkdir_p(@io_directory)
      if recheck_ids
        @found_resource_path = io_directory.join(recheck_output_file)
      else
        @timestamp_file_path = io_directory.join("since.txt")
        @since = @timestamp_file_path.read if @timestamp_file_path.exist?
        @found_resource_path = io_directory.join(full_audit_output_file)
        @found_resources = Set.new(@found_resource_path.read.split.map { |x| Valkyrie::ID.new(x) }) if @found_resource_path.exist?
      end
    end

    def resource_query
      if recheck_ids
        query_service.custom_queries.memory_efficient_find_many_by_ids(ids: ids_from_csv)
      else
        query_service.custom_queries.memory_efficient_all(except_models: unpreserved_models, order: true, since: since)
      end
    end

    def ids_from_csv
      @ids_from_csv ||= CSV.read(io_directory.join(full_audit_output_file)).flatten
    end
end
# rubocop:enable Metrics/ClassLength
