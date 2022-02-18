# frozen_string_literal: true

class IngestEphemeraMODS
  attr_accessor :project_id, :mods, :dir, :change_set_persister, :logger
  delegate :query_service, to: :change_set_persister

  def initialize(project_id, mods, dir, change_set_persister, logger)
    @project_id = project_id
    @mods = mods
    @dir = dir
    @change_set_persister = change_set_persister
    @logger = logger
  end

  def ingest
    return nil unless files.count.positive?
    change_set.validate(base_attributes)
    change_set.validate(title_attributes)
    change_set.validate(mods_attributes)
    change_set.validate(files: files.push(mods_file))
    change_set.validate(append_id: project_id)
    change_set_persister.save(change_set: change_set)
  end

  class IngestUkrainianEphemeraMODS < IngestEphemeraMODS
    def mods_class
      UkrainianEphemeraMODS
    end
  end

  class UkrainianEphemeraMODS < METSDocument::MODSDocument
    def geographic_origin
      ["Ukraine"]
    end

    def geographic_subject
      ["Ukraine"]
    end

    def non_name_subjects
      [
        "Politics and government--Elections",
        "Politics and government--Foreign relations",
        "Politics and government--Political campaigns",
        "Politics and government--Political parties",
        "Politics and government--Presidents",
        "Politics and government--Protest movements"
      ]
    end
  end

  class IngestGnibMODS < IngestEphemeraMODS
    def mods_class
      GnibMODS
    end

    def base_attributes
      super.merge(
        barcode: barcode,
        folder_number: folder_number
      )
    end

    def barcode
      "00000000"
    end

    def language
      code_map = {
        "eng" => "en",
        "spa" => "es",
        "fre" => "fr",
        "ger" => "de",
        "sa" => "es",
        "may" => "myn",
        "myn" => "myn",
        "dan" => "da",
        "fin" => "fi",
        "swe" => "sv"
      }

      [find_term(code: code_map[mods_doc.language.first.strip], vocab: "LAE Languages")]
    end

    def ocr_language
      mods_doc.language.map(&:strip)
    end

    def local_identifier
      folder_number + "_" + File.basename(dir)
    end

    def folder_number
      record_identifier = mods_doc.record_identifier
      path = URI(record_identifier).path
      path.split("/")[-2]
    end
  end

  class GnibMODS < METSDocument::MODSDocument
    def geographic_subject
      ["Guatemala"]
    end

    def non_name_subjects
      topics = normalize_whitespace(value_from(xpath: "mods:subject//mods:topic")).map(&:strip)
      topics.map { |topic| "topic--#{topic}" }
    end
  end

  class IngestMoscowMODS < IngestEphemeraMODS
    def mods_class
      MoscowMODS
    end
  end

  class MoscowMODS < METSDocument::MODSDocument
    def non_name_subjects
      topics = normalize_whitespace(value_from(xpath: "mods:subject//mods:topic")).map(&:strip)
      topics.map { |topic| "topic--#{topic}" }
    end
  end

  private

    def change_set
      @change_set ||= BoxlessEphemeraFolderChangeSet.new(EphemeraFolder.new)
    end

    def mods_attributes
      {
        sort_title: mods_doc.sort_title,
        alternative_title: mods_doc.alternative_title,
        series: mods_doc.series,
        description: mods_doc.note,
        publisher: mods_doc.publisher,
        creator: mods_doc.creator,
        date_created: mods_doc.date_created,
        genre: find_term(label: mods_doc.genre, vocab: "LAE Genres"),
        subject: subjects,
        local_identifier: local_identifier,
        language: language,
        geographic_origin: [find_term(label: mods_doc.geographic_origin.first, vocab: "LAE Areas")],
        geo_subject: [find_term(label: mods_doc.geographic_subject.first, vocab: "LAE Areas")],
        height: height_from_extent,
        width: width_from_extent,
        page_count: page_count,
        ocr_language: ocr_language
      }
    end

    def local_identifier
      File.basename(dir)
    end

    def language
      [find_term(code: mods_doc.language.first, vocab: "LAE Languages")]
    end

    def ocr_language
      []
    end

    def subjects
      mods_doc.non_name_subjects.map do |t|
        parts = t.split("--")
        find_term(label: parts[1], vocab: parts[0])
      end
    end

    def mods_doc
      @mods_doc ||= mods_class.new(Nokogiri::XML(File.read(mods)).root)
    end

    def mods_class
      METSDocument::MODSDocument
    end

    def height_from_extent
      match = mods_doc.extent.first&.match(/.* (\d+) cm\.*/)
      match[1] if match
    end

    def width_from_extent
      match = mods_doc.extent.first&.match(/.*?(\d+) cm.*/)
      match[1] if match
    end

    def page_count
      match = mods_doc.extent.first&.match(/(\d+) .+ ; .*/)
      return match[1] if match
      files.length
    end

    def find_term(label: nil, code: nil, vocab: nil)
      query_service.custom_queries.find_ephemera_term_by_label(label: label, code: code, parent_vocab_label: vocab).id
    rescue
      label
    end

    def title_attributes
      return {title: native_title, transliterated_title: transliterated_title} if native_title
      {title: first_title}
    end

    def native_title
      mods_doc.title.find { |t| t.respond_to?(:language) && !t.language.to_s.downcase.end_with?("latn") }
    end

    def transliterated_title
      mods_doc.title.find { |t| t.respond_to?(:language) && t.language.to_s.downcase.end_with?("latn") }
    end

    def first_title
      mods_doc.title.first
    end

    def base_attributes
      {
        rights_statement: RightsStatements.copyright_not_evaluated.to_s
      }
    end

    def files
      @files ||= Dir["#{dir}/*.tif"].sort.map do |file|
        IngestableFile.new(
          file_path: file,
          mime_type: "image/tiff",
          original_filename: File.basename(file),
          copyable: true
        )
      end
    end

    def mods_file
      IngestableFile.new(
        file_path: mods,
        mime_type: "application/xml; schema=mods",
        original_filename: File.basename(mods),
        copyable: true
      )
    end
end
