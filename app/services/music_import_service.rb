# frozen_string_literal: true

# A service class to run an import of music reserves and performance recording
#   objects from a sql server database into figgy
class MusicImportService
  attr_reader :recordings, :sql_server_adapter, :postgres_adapter, :logger, :cache
  delegate :recordings, to: :recordings_collector
  def initialize(sql_server_adapter:, postgres_adapter:, logger:, cache: true)
    @sql_server_adapter = sql_server_adapter
    @postgres_adapter = postgres_adapter
    @logger = logger
    @cache = cache
  end

  def recordings_collector
    @recordings_collector ||= RecordingCollector.new(sql_server_adapter: sql_server_adapter, postgres_adapter: postgres_adapter, logger: logger, cache: cache)
  end

  # yes there will be a #run method but the first step is the call number report
  def bibid_report
    suspected_playlists, real_recordings = recordings.partition { |rec| rec.call&.starts_with? "x-" }
    numbered_courses, rest = real_recordings.partition { |rec| rec.courses.any? { |course| course.match?(/^[a-zA-Z]{3}\d+.*$/) } }
    empty_courses, other_courses = rest.partition { |rec| rec.courses.empty? }

    log_multiple_bibs(real_recordings)
    log_missing_bibs(recordings: suspected_playlists, prefix: "Suspected playlist / no bibs")
    log_missing_bibs(recordings: numbered_courses, prefix: "Numbered course / no bibs")
    log_missing_bibs(recordings: other_courses, prefix: "Other course / no bibs")

    logger.info "Report Summary"
    logger.info "--------------"
    logger.info "Bib ids found in #{number_empty(suspected_playlists)} of #{suspected_playlists.count} recordings (suspected playlists) " \
      "where call number starts with 'x-' (#{percent_empty(suspected_playlists)}%)"
    logger.info "Removed suspected playlists from remaining stats"
    logger.info "--------------"
    logger.info "Bib ids found in #{number_empty(real_recordings)} of #{real_recordings.count} recordings (#{percent_empty(real_recordings)}%)"
    bad_recordings = recordings.select { |x| x.bibs.length > 1 }
    found_ids = bad_recordings.select { |x| x.recommended_bib.present? }
    logger.info "Found recommended bib for #{found_ids.length} of #{bad_recordings.length} records with multiple bib ids"
    logger.info "--------------"
    logger.info "Bib ids found in #{number_empty(numbered_courses)} of #{numbered_courses.count} recordings with numbered course names (#{percent_empty(numbered_courses)}%)"
    logger.info "Bib ids found in #{number_empty(other_courses)} of #{other_courses.count} recordings with other course names (#{percent_empty(other_courses)}%)"
    logger.info "#{empty_courses.count} recordings not in any course"
  end

  private

    def number_empty(recordings)
      recordings.reject { |rec| rec.bibs.empty? }.count
    end

    def percent_empty(recordings)
      (number_empty(recordings) / recordings.count.to_f * 100).to_i
    end

    def log_multiple_bibs(recordings)
      recordings.select { |rec| rec.bibs.count > 1 }.each do |rec|
        logger.info "multiple bibs id: #{rec.id}, bibs: #{rec.bibs}, call: #{rec.call}, courses: #{rec.courses}"
      end
    end

    def log_missing_bibs(recordings:, prefix:)
      missing, _present = recordings.partition { |rec| rec.bibs.empty? }
      missing.each do |rec|
        logger.info "#{prefix} id: #{rec.id}, call: #{rec.call}, title: #{rec.titles.first}, courses: #{rec.courses}"
      end
    end
end
