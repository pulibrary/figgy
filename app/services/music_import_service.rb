# frozen_string_literal: true

# A service class to run an import of music reserves and performance recording
#   objects from a sql server database into figgy
class MusicImportService
  attr_reader :recordings, :sql_server_adapter, :postgres_adapter, :logger
  def initialize(sql_server_adapter:, postgres_adapter:, logger:)
    @sql_server_adapter = sql_server_adapter
    @postgres_adapter = postgres_adapter
    @logger = logger
  end

  # yes there will be a #run method but the first step is the call number report
  def bibid_report
    process_recordings
    suspected_playlists, real_recordings = recordings.partition { |rec| rec.call&.starts_with? "x-" }
    numbered_courses, rest = real_recordings.partition { |rec| rec.courses.any? { |course| course.match?(/^[a-zA-Z]{3}\d+$/) } }
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
    logger.info "--------------"
    logger.info "Bib ids found in #{number_empty(numbered_courses)} of #{numbered_courses.count} recordings with numbered course names (#{percent_empty(numbered_courses)}%)"
    logger.info "Bib ids found in #{number_empty(other_courses)} of #{other_courses.count} recordings with other course names (#{percent_empty(other_courses)}%)"
    logger.info "#{empty_courses.count} recordings not in any course"
  end

  def process_recordings
    load_recordings
    reconcile_call_numbers
  end

  # SQL QUERIES
  def recordings_query
    "select R.idRecording, R.CallNo, C.CourseNo from Recordings R " \
      "left join Selections S on S.idRecording=R.idRecording " \
      "left join jSelections jS on S.idSelection=jS.idSelection " \
      "left join Courses C on jS.idCourse=C.idCourse"
  end

  def bib_query(column:, call_num:)
    "SELECT bibid, title from orangelight_call_numbers where #{column}='#{call_num}'"
  end

  private

    def load_recordings
      logger.info "loading recordings"
      results = sql_server_adapter.execute(query: recordings_query).group_by { |result| result["idRecording"] }
      @recordings = results.map do |result|
        MRRecording.new(result.first,
                        result.second.first["CallNo"], # call number comes from recording so is same for each entry
                        result.second.map { |t| t["CourseNo"] }.uniq.compact) # comes from joins
      end
    end

    def reconcile_call_numbers
      logger.info "reconciling callnumbers to bibids"
      @recordings.each do |rec|
        logger.info "reconciling call number for #{rec}"
        rec.bibs = bib_numbers_for(call_number: rec.call)
        logger.info "  got #{rec.bibs}"
      end
    end

    def bib_numbers_for(call_number:)
      return [] unless call_number
      bib_numbers = []
      normalization_strategies.each_pair do |strategy, column|
        next unless bib_numbers.empty?
        normalized = send(strategy, call_number)
        bib_numbers = query_ol(column: column, call_number: normalized)
        logger.info "Found bib with #{strategy} for #{call_number}" unless bib_numbers.empty?
      end
      bib_numbers
    end

    def normalization_strategies
      { space_after_hyphen: "label",
        space_replace_hyphen: "label",
        space_after_hyphen_lc: "sort",
        space_replace_hyphen_lc: "sort",
        just_lc: "sort" }
    end

    # check the call numbers database for the call number given
    # If multiple call numbers are found, gets all the bibs from the ol API
    # @return Array of bib id strings, may be empty
    def query_ol(column:, call_number:)
      result = postgres_adapter.execute(query: bib_query(column: column, call_num: call_number))
      return [] if result.empty?
      if result.first["title"].match?(/^[\d]+ titles with this call number$/)
        logger.info "  trying ol"
        bib_numbers = query_ol_api(call_number: call_number)
      else
        bib_numbers = result.map { |h| h["bibid"] }
      end
      bib_numbers
    end

    # query orangelight as a backup for when the database returns a querystring param
    #   "label"=>"CD- 9221",
    #   e.g. "?f[call_number_browse_s][]=CD-+9221"
    def query_ol_api(call_number:)
      conn = Faraday.new(url: "https://catalog.princeton.edu/catalog.json")
      result = conn.get do |req|
        req.params["search_field"] = "all_fields"
        req.params["f[call_number_browse_s][]"] = call_number
      end

      json = JSON.parse result.body
      # return nil unless json["response"]["docs"].count.positive?
      json["response"]["docs"].map { |doc| doc["id"] } # will be [] if no results
    end

    # apply normalization which replaces a space with a hyphen
    def space_after_hyphen(call_number)
      return unless call_number
      general_normalization(call_number) do |cn|
        # dashes should be followed by spaces e.g. cd-10994
        # ls, cass, dat, cd, vcass, dvd
        if cn.match?(/^((CD)||(DAT)||(CASS)||(LS)||(VCASS)||(DVD))-/)
          cn = cn.sub("-", "- ")
        end
        cn
      end
    end

    # apply normalization which adds a space after a hyphen
    def space_replace_hyphen(call_number)
      return unless call_number
      general_normalization(call_number) do |cn|
        # dashes should be followed by spaces e.g. cd-10994
        # ls, cass, dat, cd, vcass, dvd
        if cn.match?(/^((CD)||(DAT)||(CASS)||(LS)||(VCASS)||(DVD))-/)
          cn = cn.sub("-", " ")
        end
        cn
      end
    end

    def space_after_hyphen_lc(call_number)
      return unless call_number
      general_normalization(call_number) do |cn|
        # dashes should be followed by spaces e.g. cd-10994
        # ls, cass, dat, cd, vcass, dvd
        if cn.match?(/^((CD)||(DAT)||(CASS)||(LS)||(VCASS)||(DVD))-/)
          cn = cn.sub("-", "- ")
        end
        cn = ol_cn_normalize(cn)
        cn
      end
    end

    def space_replace_hyphen_lc(call_number)
      return unless call_number
      general_normalization(call_number) do |cn|
        # dashes should be followed by spaces e.g. cd-10994
        # ls, cass, dat, cd, vcass, dvd
        if cn.match?(/^((CD)||(DAT)||(CASS)||(LS)||(VCASS)||(DVD))-/)
          cn = cn.sub("-", " ")
        end
        cn = ol_cn_normalize(cn)
        cn
      end
    end

    def just_lc(call_number)
      return unless call_number
      ol_cn_normalize(call_number).gsub(/'/, "''")
    end

    def general_normalization(call_number)
      # they're uppercase in the catalog
      call_number = call_number.upcase
      # strip volume designations, e.g. cd-24583v1
      call_number = call_number.gsub(/V[0-9]+$/, "")
      call_number = yield(call_number)
      # escape single quotes in a call number
      call_number.gsub(/'/, "''")
    end

    # these 2 methods taken straight from orangelight; they're used when loading the db
    # https://github.com/pulibrary/orangelight/blob/ae71aa558329e2cad38e948de6c642737b9e8ef6/lib/orangelight/string_functions.rb#L5-L11
    def ol_cn_normalize(str)
      if /^[a-zA-Z]{2,3} \d+([qQ]?)$/.match? str # the normalizer thinks "CD 104" is valid LC
        accession_number(str)
      else
        Lcsort.normalize(str.gsub(/x([A-Z])/, '\1')) || accession_number(str)
      end
    end

    def accession_number(str)
      norm = str.upcase
      norm = norm.gsub(/(CD|DVD|LP|LS)-/, '\1') # should file together regardless of dash
      # normalize number to 7-digits, ignore oversize q
      norm.gsub(/(\d+)(Q?)$/) { format("%07d", Regexp.last_match[1].to_i) }
    end

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
        logger.info "#{prefix} id: #{rec.id}, call: #{rec.call}, courses: #{rec.courses}"
      end
    end

    MRRecording = Struct.new(
      :id,
      :call,
      # course number of the course which links to this recording
      #   needed for splitting the report out along course number characteristics
      :courses, # an array
      :bibs, # an array
      # id of Recording for which this is recording represents a playlist
      :duplicate
    )
end
