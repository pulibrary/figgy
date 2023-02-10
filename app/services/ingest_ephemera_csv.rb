# frozen_string_literal: true
require "csv"

class IngestEphemeraCSV
  attr_accessor :project_id, :mdata_table, :imgdir, :change_set_persister, :logger, :validation_errors
  delegate :query_service, to: :change_set_persister

  def initialize(project_id, mdata_file, imgdir, change_set_persister, logger)
    @mdata_table = CSV.read(mdata_file, headers: true, header_converters: :symbol)
    @imgdir = imgdir
    @change_set_persister = change_set_persister
    @logger = logger
    @project_id = project_id
    @validation_errors = []
  end

  def ingest
    mdata_table.collect do |row|
      logger.info "Ingesting row #{row}"
      change_set = BoxlessEphemeraFolderChangeSet.new(EphemeraFolder.new)
      folder_data = FolderData.new(base_path: imgdir,
                                   change_set_persister: change_set_persister,
                                   persist_p: false,
                                   **row.to_h)
      change_set.validate(folder_data.attributes)
      change_set.validate(files: folder_data.files)
      change_set.validate(append_id: project_id) # relies on append_to_parent feature of change_set
      change_set_persister.save(change_set: change_set) # finally, persist the change set
    end
  end

  def validate
    logger.info "beginning validation"
    @validation_errors = {}
    mdata_table.each_with_index do |row, index|
      folder_data = FolderData.new(base_path: imgdir,
                                   change_set_persister: change_set_persister,
                                   persist_p: false,
                                   **row.to_h)
      change_set = BoxlessEphemeraFolderChangeSet.new(EphemeraFolder.new)
      change_set.validate(folder_data.attributes)
      change_set.validate(files: folder_data.files)
      @validation_errors[index + 1] = change_set.errors.messages unless change_set.errors.messages.empty?
    end
    @validation_errors.empty?
  end
end

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/AbcSize

class FolderData
  attr_accessor :image_path, :fields, :change_set_persister, :vocab_service, :logger
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, :persister, to: :metadata_adapter

  def initialize(base_path:, change_set_persister:, persist_p: false, logger: Logger.new(STDOUT), **arg_fields)
    @image_path = File.join(base_path, arg_fields[:path])
    @fields = arg_fields.except(:path)
    @change_set_persister = change_set_persister
    @logger = logger
    @vocab_service = VocabularyService::EphemeraVocabularyService.new(change_set_persister: change_set_persister,
                                                                      persist_if_not_found: persist_p)
  end

  # rubocop:disable Metrics/MethodLength
  def attributes
    {
      member_ids: Array(fields[:member_ids]),
      barcode: barcode,
      folder_number: Set.new(Array(fields[:folder_number])),
      local_identifier: fields[:local_identifier],
      title: title,
      sort_title: Set.new(Array(fields[:sort_title])),
      alternative_title: Set.new(Array(fields[:alternative_title])),
      transliterated_title: Set.new(Array(fields[:transliterated_title])),
      language: Array(language),
      genre: genre,
      width: Set.new(Array(fields[:width])),
      height: Set.new(Array(fields[:height])),
      page_count: page_count,
      rights_statement: RightsStatements.copyright_not_evaluated.to_s,
      rights_note: Set.new(Array(fields[:rights_note])),
      series: Set.new(Array(fields[:series])),
      creator: creator,
      contributor: Set.new(Array(fields[:contributor])),
      publisher: publishers,
      geographic_origin: geographic_origin,
      subject: subject,
      geo_subject: geo_subject,
      description: fields[:description],
      date_created: date_created,
      provenance: Set.new(Array(fields[:provenance])),
      depositor: Set.new(Array(fields[:depositor])),
      date_range: date_range,
      ocr_language: Array(ocr_language),
      keywords: Set.new(keywords),
      member_of_collection_ids: member_of_collection_ids,
      append_collection_ids: member_of_collection_ids
    }
  end

  # rubocop:enable Metrics/MethodLength

  def date_range
    return unless fields[:date_range_start].present? && fields[:date_range_end].present?
    DateRange.new(start: fields[:date_range_start], end: fields[:date_range_end], approximate: fields[:date_range_approximate].present?)
  end

  def creator
    return [] if fields[:creator].blank?
    fields[:creator].split(";").collect(&:strip)
  end

  def title
    return [] if fields[:title].blank?
    @title ||= Array(fields[:title])
  end

  def files
    return @files unless @files.nil?
    raise IOError, format("%s does not exist", image_path) unless File.directory?(image_path)
    @files ||= Dir.glob("#{image_path}/*.{tif,tiff,jpg,jpeg,png}", File::FNM_CASEFOLD).sort.map do |file|
      IngestableFile.new(
        file_path: file,
        mime_type: case File.extname(file)
                   when ".tif", ".tiff", ".TIFF", ".TIF" then "image/tiff"
                   when ".jpeg", ".jpg" then "image/jpeg"
                   when ".png" then "image/png"
                   end,
        original_filename: File.basename(file),
        copy_before_ingest: true
      )
    end
  end

  def barcode
    fields[:barcode] || "0000000000"
  end

  def page_count
    if fields[:page_count]
      Array(fields[:page_count])
    else
      Array(Array(files).size.to_s)
    end
  end

  def date_created
    return if fields["date_created"] == "Unknown"
    fields[:date_created]
  end

  def find_language(language_code)
    vocab_service.find_term(code: language_code, vocab: "LAE Languages").id
  rescue => e
    logger.warn format("%s: No term for %s", e.class, language_code)
  end

  def language
    return if fields[:language].blank?
    @language ||= fields[:language].split(";").collect { |lang| find_language(lang.strip) }
  end

  def ocr_language
    return if fields[:ocr_language].blank?
    @ocr_language ||= fields[:ocr_language].split(";").collect(&:strip)
  end

  def geographic_origin
    return if fields[:geographic_origin].blank?
    @geographic_origin ||= vocab_service.find_term(label: Array(fields[:geographic_origin]).first, vocab: "LAE Geographic Areas")
  end

  def keywords
    return if fields[:keywords].blank?
    fields[:keywords].split(";").collect(&:strip)
  end

  def subject
    return if fields[:subject].blank?
    subjects = fields[:subject].split(/;|\//).map { |s| s.strip.split("--") }.map { |c, s| { "category" => c, "topic" => s } }
    subjects.uniq.map do |sub|
      subject = vocab_service.find_subject_by(category: sub["category"], topic: sub["topic"])
    rescue => e
      logger.warn format("%s: no subject for %s", e.class, sub)
    else
      subject&.id
    end
  end

  def geo_subject
    return if fields[:geo_subject].blank?
    Array(vocab_service.find_term(label: Array(fields[:geo_subject]).first, vocab: "LAE Geographic Areas"))
  end

  def publishers
    headers = fields.keys.find_all { |e| /^publisher/ =~ e.to_s }
    headers.collect { |h| fields[h] }
  end

  def member_of_collection_ids
    headers = fields.keys.find_all { |e| /^member_of_collection/ =~ e.to_s }
    collection_titles = headers.collect { |h| fields[h] }
    collection_titles.collect do |title|
      collections = query_service.custom_queries.find_by_property(
        property: :title, value: title
      )
      begin
        collections.first.id
      rescue
        logger.warn format("no collection with title %s", title)
      end
    end
  end

  def genre
    return if fields[:genre].blank?
    term = vocab_service.find_term(label: fields[:genre])
    return term.id unless term.nil?
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/AbcSize
