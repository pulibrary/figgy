# frozen_string_literal: true
require "csv"

class IngestEphemeraCSV
  attr_accessor :project_id, :mdata, :imgdir, :change_set_persister, :logger
  delegate :query_service, to: :change_set_persister

  def initialize(project_id, mdata_file, imgdir, change_set_persister, logger)
    @project_id = project_id
    @mdata_file = mdata_file
    @imgdir = imgdir
    @change_set_persister = change_set_persister
    @logger = logger
  end

  def ingest
    mdata.each do |row|
      folder_data = FolderData.new(row.to_h)
      change_set.validate(folder_data.attributes)
      change_set.validate(files: folder_data.files)
      change_set.validate(append_id: project_id)
      change_set_persister.save(change_set: change_set)
    end
  end


  def mdata
    @mdata ||= CSV.table(@mdata_file)
  end

  class FolderData
    def initialize(**attributes)

    end
  end
  
  private

    def change_set
      @change_set ||= BoxlessEphemeraFolderChangeSet.new(EphemeraFolder.new)
    end

    def mdata_attributes
      {
        creator: mdata[:creator],
        description: mdata[:description],
        date_created: mdata[:date_created],
        geo_subject:  mdata[:geographic_subject]
      }
    end        

    def find_term(label: nil, code: nil, vocab: nil)
      query_service.custom_queries.find_ephemera_term_by_label(label: label, code: code, parent_vocab_label: vocab).id
    rescue
      label
    end

    def title_attributes
      { title: mdata[:title] }
    end

    def first_title
      mdata[:title].first
    end

    def base_attributes
      {
        rights_statement: RightsStatements.copyright_not_evaluated.to_s
      }
    end

    def files
      @files || Dir.glob("#{dir}/*.{tif,jpg,jpeg,png}").sort.map do |file|
        IngestableFile.new(
          file_path: file,
          mime_type: case File.extname(file)
                     when ".tif" then "image/tiff"
                     when ".jpeg",".jpg" then "image/jpeg"
                     when ".png" then "image/png"
                     end,
          original_filename: File.basename(file),
          copyable: true
          )          
      end
    end

    def csv_file
      IngestableFile.new(
        file_path: mdata,
        mime_type: "text/csv",
        original_filename: File.basename(mods),
        copyable: true
      )
    end
end
