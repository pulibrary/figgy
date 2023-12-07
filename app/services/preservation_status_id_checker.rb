# frozen_string_literal: true

# Checks resources listed in a given file.
class PreservationStatusIdChecker < PreservationStatusReporter
  def audited_resource_count
    ids_from_csv.count
  end

  # We're not saving state for resumability, but we want to
  #   set the the input and output destinations
  def load_state!(state_directory:)
    @state_directory = Pathname.new(state_directory)
    FileUtils.mkdir_p(state_directory)
    @found_resource_path = state_directory.join(output_filename)
  end

  def processed(last_checked:, bad_resource_ids:)
    File.open(@found_resource_path, "a") do |f|
      bad_resource_ids.each do |resource_id|
        f.puts resource_id
      end
    end
  end

  def csv_path
    @state_directory.join(@input_filename)
  end

  # this checker uses the reporter's output as its input
  def output_filename
    @input_filename = super
    "bad_resources_recheck.txt"
  end

  private

    def resource_query
      query_service.custom_queries.memory_efficient_find_many_by_ids(ids: ids_from_csv)
    end

    def ids_from_csv
      @ids_from_csv ||= CSV.read(csv_path).flatten
    end
end
