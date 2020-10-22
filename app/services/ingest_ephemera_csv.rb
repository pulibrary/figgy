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
      folder_data = FolderData.new(base_path: imgdir, **row.to_h)
      change_set.validate(folder_data.attributes)
      change_set.validate(files: folder_data.files)
      change_set.validate(append_id: project_id)
      change_set_persister.save(change_set: change_set)
    end
  end

  class FolderData
    attr_accessor :image_path, :fields

    def initialize(base_path:, **arg_fields)
      @image_path = File.join(base_path, arg_fields[:path])
      @fields = arg_fields.except(:path)
    end

    def attributes
      {
        member_ids: Array(fields[:member_ids]),
        title: Array(fields[:title] || "untitled"),
        sort_title: Set.new(Array(fields[:sort_title])),
        alternative_title: Set.new(Array(fields[:alternative_title])),
        transliterated_title: Set.new(Array(fields[:transliterated_title])),
        language: Set.new(Array(fields[:language])),
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
        geo_subject: Set.new(Array(fields[:geo_subject])),
        description: Set.new(Array(fields[:description])),
        date_created: Set.new(Array(fields[:date_created])),
        provenance: Set.new(Array(fields[:provenance])),
        depositor: Set.new(Array(fields[:depositor])),
        date_range: Array(fields[:date_range]),
        ocr_language: Set.new(Array(fields[:ocr_language])),
        keywords: Set.new(Array(fields[:keywords]))
      }
    end

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
  end

  private

    def change_set
      @change_set ||= BoxlessEphemeraFolderChangeSet.new(EphemeraFolder.new)
    end
end
