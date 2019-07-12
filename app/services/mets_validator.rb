#frozen_string_literal: true
class MetsValidator
  attr_reader :query_service
  def initialize(query_service)
    @query_service = query_service
    @logger = Logger.new(STDOUT)
  end

  def validate(mets_file)
    mets = METSDocument.new(mets_file)
    match = find(mets.pudl_id, mets.bib_id)
    unless match
      logger.info "unable to find match for #{mets.pudl_id} (#{mets.bib_id})"
      return
    end

    logger.info "checking #{mets.pudl_id}"
    checksums = match.decorate.file_sets.map { |fs| fs.original_file.checksum.first.md5 }
    file_summary = { true: 0, false: 0 }
    mets.files.each do |file_info|
      found = checksums.contain?(file_info["checksum"])
      file_summary[found] += 1
      logger.info "f: #{file_info[:replaces]}: #{file_info[:checksum]}: found: #{found}"
    end
    puts "  files found: #{file_summary[true]}, not found: #{file_summary[false]}"
  end

  def find(replaces, bib)
    repl = query_service.custom_queries.find_by_property(property: :replaces, value: replaces)
    return repl.first if repl.first

    source = query_service.custom_queries.find_by_property(property: :source_metadata_identifier, value: bib)
    return source.first if source.first
  end
end
