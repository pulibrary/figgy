# frozen_string_literal: true
class MusicImportService::RecordingCollector
  attr_reader :recordings, :sql_server_adapter, :postgres_adapter, :logger, :cache
  def initialize(sql_server_adapter:, postgres_adapter:, logger:, cache: true)
    @sql_server_adapter = sql_server_adapter
    @postgres_adapter = postgres_adapter
    @logger = logger
    @cache = cache
  end

  def recordings
    @recordings ||=
      begin
        if cache && File.exist?("tmp/recordings_cache.dump")
          Marshal.load(File.open("tmp/recordings_cache.dump"))
        else
          logger.info "loading recordings"
          results = sql_server_adapter.execute(query: recordings_query).group_by { |result| result["idRecording"] }
          results = results.map do |result|
            MRRecording.new(result.first,
                            result.second.first["CallNo"], # call number comes from recording so is same for each entry
                            result.second.map { |t| t["CourseNo"] }.uniq.compact, # comes from joins
                            result.second.map { |t| t["RecTitle"] }.uniq.compact)
          end
          logger.info "reconciling callnumbers to bibids"
          results.each do |rec|
            logger.info "reconciling call number for #{rec}"
            rec.bibs = bib_numbers_for(call_number: rec.call)
            logger.info "  got #{rec.bibs}"
          end
          # Find bibs via title
          @found_bibs = 0
          results.select { |x| x.bibs.empty? }.each do |recording|
            populate_bib_from_title(recording)
          end
          # Find "correct" bib via Leveshtein distance.
          results.select { |x| x.bibs.length > 1 }.each do |recording|
            bib_records = bib_records_from_recording(recording).select(&:present?)
            recording.recommended_bib = bib_records.find { |x| x[:title_distance] <= 6 }.try(:[], :id)
          end
          store_cached_bibs
          logger.info "Found #{@found_bibs} bibs from searching"
          if cache
            File.open("tmp/recordings_cache.dump", "wb") do |f|
              f.puts Marshal.dump(recordings)
            end
          end
          results
        end
      end
  end

  def populate_bib_from_title(recording)
    logger.info "populating bib from title for #{recording.titles.first}"
    ol_response = JSON.parse(
      open(
        "https://catalog-staging.princeton.edu/catalog.json?f[access_facet][]=In+the+Library&f[format][]=Audio&f[location][]=Mendel+Music+Library" \
        "&search_field=title&rows=100&q=#{CGI.escape(recording.titles.first)}"
      ).read
    )
    docs = ol_response["response"]["docs"]
    docs.map do |doc|
      doc["distance"] = distance(doc["title_display"], recording.titles.first)
    end
    matching_docs = docs.select { |x| x["distance"] <= 6 }
    return if matching_docs.length != 1
    recording.bibs = [matching_docs[0]["id"]]
    logger.info "found id from title for #{recording.titles.first} - matched with #{matching_docs.first['title_display']}"
    @found_bibs += 1
  rescue StandardError
    logger.info "Errored trying to populate bib."
  end

  # SQL QUERIES
  def recordings_query
    "select R.idRecording, R.CallNo, R.RecTitle, C.CourseNo from Recordings R " \
      "left join Selections S on S.idRecording=R.idRecording " \
      "left join jSelections jS on S.idSelection=jS.idSelection " \
      "left join Courses C on jS.idCourse=C.idCourse"
  end

  def bib_query(column:, call_num:)
    "SELECT bibid, title from orangelight_call_numbers where #{column}='#{call_num}'"
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
      just_lc: "sort",
      volume_expansion: "label",
      volume_space_expansion: "label" }
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
      bib_numbers = result.map { |h| h["bibid"] }.uniq
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

  def volume_expansion(call_number)
    return unless call_number
    call_number = call_number.upcase
    if call_number.match?(/^((CD)||(DAT)||(CASS)||(LS)||(VCASS)||(DVD))-/)
      call_number = call_number.sub("-", "- ").sub("V", " vol.")
    end
    call_number = call_number.gsub(/'/, "''")
    call_number
  end

  def volume_space_expansion(call_number)
    return unless call_number
    call_number = call_number.upcase
    if call_number.match?(/^((CD)||(DAT)||(CASS)||(LS)||(VCASS)||(DVD))-/)
      call_number = call_number.sub("-", "- ").sub("V", " vol. ")
    end
    call_number = call_number.gsub(/'/, "''")
    call_number
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

  def bib_records_from_recording(recording)
    logger.info "getting recommended bib for #{recording.call}"
    records = recording.bibs.map do |bib_id|
      output = cached_bib(bib_id)
      bib_title = Array.wrap(output["title"]).map do |title|
        if title.is_a?(Hash)
          title["@value"]
        else
          title
        end
      end.first
      next {} if bib_title.blank? || recording.titles.first.blank?
      {
        id: bib_id,
        title: bib_title,
        title_distance: distance(bib_title, recording.titles.first)
      }
    end
    records.sort_by { |x| x[:title_distance] || 3000 }
  end

  def distance(string1, string2)
    string1.downcase.include?(string2.downcase) ? 5 : DamerauLevenshtein.distance(string1, string2)
  end

  def cached_bib(bib_id)
    cached_bibs.fetch(bib_id) do
      begin
        cached_bibs[bib_id] = JSON.parse(open("https://bibdata.princeton.edu/bibliographic/#{bib_id}/jsonld").read)
      rescue
        cached_bibs[bib_id] = {}
      end
      cached_bibs[bib_id]
    end
  end

  def store_cached_bibs
    return unless cache
    File.open("tmp/cached_bibs.dump", "wb") do |file|
      file.puts Marshal.dump(cached_bibs)
    end
  end

  def cached_bibs
    @cached_bibs ||=
      begin
        if cache && File.exist?("tmp/cached_bibs.dump")
          Marshal.load(File.open("tmp/cached_bibs.dump"))
        else
          {}
        end
      end
  end

  MRRecording = Struct.new(
    :id,
    :call,
    # course number of the course which links to this recording
    #   needed for splitting the report out along course number characteristics
    :courses, # an array
    :titles, # an array
    :bibs, # an array
    # id of Recording for which this is recording represents a playlist
    :duplicate,
    :recommended_bib
  )
end
