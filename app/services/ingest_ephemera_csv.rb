# frozen_string_literal: true
require "csv"

class IngestEphemeraCSV
  attr_accessor :project_id, :mdata_table, :imgdir, :change_set_persister, :logger
  delegate :query_service, to: :change_set_persister

  def initialize(project_id, mdata_file, imgdir, change_set_persister, logger)
    @project_id = project_id
    @mdata_table = CSV.read(mdata_file, headers: true, header_converters: :symbol)
    @imgdir = imgdir
    @change_set_persister = change_set_persister
    @logger = logger
  end

  def ingest
    mdata_table.collect do |row|
      folder_data = FolderData.new(base_path: imgdir, change_set_persister: change_set_persister,  **row.to_h)
      change_set.validate(folder_data.attributes)
      change_set.validate(files: folder_data.files)
      change_set.validate(append_id: project_id)
      change_set_persister.save(change_set: change_set)
    end
  end

  class FolderData
    attr_accessor :image_path, :fields, :change_set_persister
    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, :persister, to: :metadata_adapter

    def initialize(base_path:, change_set_persister:,  **arg_fields)
      @image_path = File.join(base_path, arg_fields[:path])
      @fields = arg_fields.except(:path)
      @change_set_persister = change_set_persister
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def attributes
      {
        member_ids: Array(fields[:member_ids]),
        title: Array(fields[:title] || "untitled"),
        sort_title: Set.new(Array(fields[:sort_title])),
        alternative_title: Set.new(Array(fields[:alternative_title])),
        transliterated_title: Set.new(Array(fields[:transliterated_title])),
        language: language,
        genre: fields[:genre],
        width: Set.new(Array(fields[:width])),
        height: Set.new(Array(fields[:height])),
        page_count: Set.new(Array(fields[:page_count])),
        rights_statement: RightsStatements.copyright_not_evaluated.to_s,
        rights_note: Set.new(Array(fields[:rights_note])),
        series: Set.new(Array(fields[:series])),
        creator: Set.new(Array(fields[:creator])),
        contributor: Set.new(Array(fields[:contributor])),
        publisher: Set.new(Array(fields[:publisher])),
        geographic_origin: Array(fields[:geographic_origin]),
        subject: Set.new(Array(fields[:subject])),
        geo_subject: geo_subject,
        description: Set.new(Array(fields[:description])),
        date_created: Set.new(Array(fields[:date_created])),
        provenance: Set.new(Array(fields[:provenance])),
        depositor: Set.new(Array(fields[:depositor])),
        date_range: Array(fields[:date_range]),
        ocr_language: Set.new(Array(fields[:ocr_language])),
        keywords: Set.new(Array(fields[:keywords]))
      }
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def files
      @files || Dir.glob("#{image_path}/*.{tif,jpg,jpeg,png}").sort.map do |file|
        IngestableFile.new(
          file_path: file,
          mime_type: case File.extname(file)
                     when ".tif" then "image/tiff"
                     when ".jpeg", ".jpg" then "image/jpeg"
                     when ".png" then "image/png"
                     end,
          original_filename: File.basename(file),
          copyable: true
        )
      end
    end

    def date_created
      return if self["date_created"] == "Unknown"
      self["date_created"]
    end
    
    def names
      self["names"] || []
    end
    
    def language
      return unless fields[:language].present?
      @language ||= find_or_create_term_by(label: ISO_639.find_by_code(resource["language"]).english_name.split(";").first).id
    end
    
    def geo_origin
      return unless fields[:geo_origin].present?
      @geo_origin ||= find_or_create_term_by(label: fields[:geo_origin]).id
    end
    
    def subject
      return unless fields[:subjects].present?
      fields[:subjects].uniq.map do |sub|
        find_or_create_subject_by(category: sub["category"], topic: sub["topic"]).id
      end
    end
    
    def geo_subject
      return unless fields[:geo_subject].present?
      Array(find_term(label: Array(fields[:geo_subject]).first, vocab: "LAE Areas"))
    end

    
    def find_term(label: nil, code: nil, vocab: nil)
      query_service.custom_queries.find_ephemera_term_by_label(label: label, code: code, parent_vocab_label: vocab).id
    rescue
      label
    end

    def find_or_create_term_by(label:)
      query_service.custom_queries.find_ephemera_term_by_label(label: label) ||
        persister.save(resource: EphemeraTerm.new(label: label, member_of_vocabulary_id: imported_vocabulary.id))
    end
    
    def imported_vocabulary
      @imported_vocabulary ||= find_or_create_vocabulary_by(label: "Imported Terms")
    end
    
    def find_or_create_vocabulary_by(label:, vocabulary_id: nil)
      query_service.custom_queries.find_ephemera_vocabulary_by_label(label: label) ||
        persister.save(resource: EphemeraVocabulary.new(label: label, member_of_vocabulary_id: vocabulary_id))
    end
    
    def find_or_create_subject_by(category:, topic:)
      query_service.custom_queries.find_ephemera_term_by_label(label: topic, parent_vocab_label: category) ||
        create_subject_by(category: category, topic: topic)
    rescue
      create_subject_by(category: category, topic: topic)
    end
    
    def create_subject_by(category:, topic:)
      vocabulary = find_or_create_vocabulary_by(label: category, vocabulary_id: imported_vocabulary.id)
      persister.save(resource: EphemeraTerm.new(label: topic, member_of_vocabulary_id: vocabulary.id))
    end
  end

  private

    def change_set
      @change_set ||= BoxlessEphemeraFolderChangeSet.new(EphemeraFolder.new)
    end
end
