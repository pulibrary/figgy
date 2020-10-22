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
        subject: fields[:subject],
        title: fields[:title],
        language: fields[:language],
        genre: fields[:genre],
        page_count: fields[:page_count],
        creator: fields[:creator],
        description: fields[:description],
        date_created: fields[:date_created],
        geo_subject: [fields[:geographic_subject]]
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
