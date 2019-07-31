# frozen_string_literal: true
class MetsValidator
  attr_reader :query_service
  def initialize(query_service)
    @query_service = query_service
    @logger = Logger.new(STDOUT)
    logger.level = ENV["LOG_LEVEL"] || :info
  end

  def validate(mets_file)
    mets = METSDocument.new(mets_file)
    match = find(mets.pudl_id, mets.bib_id, mets.ark_id, mets.local_id.first)
    unless match
      logger.info "#{mets.pudl_id} X"
      return
    end

    checksums = checksums(match)
    file_summary = { true => 0, false => 0 }
    mets.files.each do |file_info|
      found = checksums.include?(file_info[:checksum])
      file_summary[found] += 1
    end
    logger.info "#{mets.pudl_id} #{match.id} #{match.state.first} #{file_summary[true]} #{file_summary[false]}"
  end

  def checksums(match)
    return match.decorate.volumes.map { |vol| checksums_for_volume(vol) }.flatten if match.respond_to?(:volumes) && !match.decorate.volumes.empty?

    checksums_for_volume(match)
  end

  def checksums_for_volume(r)
    r.decorate.file_sets.map { |fs| fs.original_file.checksum.first&.md5 }
  end

  def find(replaces, bib, ark, local_id)
    find_by(:replaces, replaces) || find_by(:source_metadata_identifier, bib) || find_by(:identifier, ark) || find_by(:local_identifier, local_id)
  end

  def find_by(property, value)
    return if value.nil? || value.blank?
    x = query_service.custom_queries.find_by_property(property: property, value: value)
    x.first if x.first
  end
end
