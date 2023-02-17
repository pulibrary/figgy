# frozen_string_literal: true
class LocalFixity
  class FixityRequestor
    def self.queue_daily_check!(annual_percent:)
      divisor = 365.0 * annual_percent
      file_set_count = query_service.custom_queries.count_all_of_model(model: FileSet)
      limit = (file_set_count / divisor).ceil
      file_sets = query_service.custom_queries.find_random_resources_by_model(limit: limit, model: FileSet)
      file_sets.each do |file_set|
        LocalFixityJob.perform_later(file_set.id.to_s)
      end
      Rails.logger.info "Enqueued #{limit} FileSets for Local Fixity Checking"
    end

    def self.query_service
      Valkyrie::MetadataAdapter.find(:postgres).query_service
    end
  end
end
