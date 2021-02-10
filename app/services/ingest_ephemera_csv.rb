# frozen_string_literal: true
require "csv"

class IngestEphemeraCSV
  attr_accessor :project_id, :mdata_table, :imgdir, :change_set_persister, :logger
  delegate :query_service, to: :change_set_persister

  def initialize(project_id, mdata_file, imgdir, change_set_persister, logger)
    @mdata_table = CSV.read(mdata_file, headers: true, header_converters: :symbol)
    @imgdir = imgdir
    @change_set_persister = change_set_persister
    @logger = logger
    @project_id = project_id
  end

  def ingest
    mdata_table.collect do |row|
      change_set = BoxlessEphemeraFolderChangeSet.new(EphemeraFolder.new)
      folder_data = FolderData.new(base_path: imgdir, change_set_persister: change_set_persister, **row.to_h)
      change_set.validate(folder_data.attributes)
      change_set.validate(files: folder_data.files)
      change_set.validate(append_id: project_id) # relies on append_to_parent feature of change_set
      change_set_persister.save(change_set: change_set) # finally, persist the change set
    end
  end
end

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/AbcSize

class FolderData
  attr_accessor :image_path, :fields, :change_set_persister, :vocab_service
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, :persister, to: :metadata_adapter

  def initialize(base_path:, change_set_persister:, **arg_fields)
    @image_path = File.join(base_path, arg_fields[:path])
    @fields = arg_fields.except(:path)
    @change_set_persister = change_set_persister
    @vocab_service = VocabularyService::EphemeraVocabularyService.new(change_set_persister: change_set_persister,
                                                                      persist_if_not_found: true)
  end

  # rubocop:disable Metrics/MethodLength
  def attributes
    {
      member_ids: Array(fields[:member_ids]),
      barcode: barcode,
      folder_number: Set.new(Array(fields[:folder_number])),
      local_identifier: fields[:local_identifier],
      title: Array(fields[:title] || "untitled"),
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
      creator: Set.new(Array(fields[:creator])),
      contributor: Set.new(Array(fields[:contributor])),
      publisher: publishers,
      geographic_origin: geographic_origin,
      subject: subject,
      geographic_subject: geographic_subject,
      description: fields[:description],
      date_created: date_created,
      provenance: Set.new(Array(fields[:provenance])),
      depositor: Set.new(Array(fields[:depositor])),
      date_range: Array(fields[:date_range]),
      ocr_language: Set.new(Array(fields[:ocr_language])),
      keywords: Set.new(Array(fields[:keywords])),
      member_of_collection_ids: member_of_collection_ids,
      append_collection_ids: member_of_collection_ids
    }
  end
  # rubocop:enable Metrics/MethodLength

  def files
    @files || Dir.glob("#{image_path}/*.{tif,tiff,jpg,jpeg,png}", File::FNM_CASEFOLD).sort.map do |file|
      IngestableFile.new(
        file_path: file,
        mime_type: case File.extname(file)
                   when ".tif", ".tiff", ".TIFF", ".TIF" then "image/tiff"
                   when ".jpeg", ".jpg" then "image/jpeg"
                   when ".png" then "image/png"
                   end,
        original_filename: File.basename(file),
        copyable: true
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
      Array(Array(files).count.to_s)
    end
  end

  def date_created
    return if fields["date_created"] == "Unknown"
    fields[:date_created]
  end

  def language
    return unless fields[:language].present?
    fields[:language].split(";").map do |lang|
      vocab_service.find_term(label: ISO_639.find_by_code(lang).english_name.split(";").first).id
    end
  end

  def geographic_origin
    return unless fields[:geographic_origin].present?
    @geographic_origin ||= vocab_service.find_term(label: Array(fields[:geographic_origin]).first, vocab: "LAE Geographic Areas")
  end

  def keywords
    return unless fields[:keywords].present?
    fields[:keywords].split(",")
  end

  def subject
    return unless fields[:subject].present?
    subjects = fields[:subject].split(";").map { |s| s.split("--") }.map { |c, s| { "category" => c, "topic" => s } }
    subjects.uniq.map do |sub|
      subject = vocab_service.find_subject_by(category: sub["category"], topic: sub["topic"])
      subject&.id
    end
  end

  def geographic_subject
    return unless fields[:geographic_subject].present?
    Array(vocab_service.find_term(label: Array(fields[:geographic_subject]).first, vocab: "LAE Geographic Areas"))
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
      collections.first.id
    end
  end

  def genre
    return unless fields[:genre].present?
    vocab_service.find_term(label: fields[:genre]).id
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/AbcSize
