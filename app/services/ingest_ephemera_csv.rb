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
    change_set.validate(base_attributes) # factor out?
    change_set.validate(title_attributes)
    change_set.validate(mdata_attributes)
    change_set.validate(append_id: project_id)
    change_set_persister.save(change_set: change_set)
  end

  def mdata
    @mdata ||= CSV.table(@mdata_file)
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
  end

  class GnibMODS < METSDocument::MODSDocument
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

    def mdata_attributes
      {
        creator: mdata[:creator],
        description: mdata[:description],
        date_created: mdata[:date_created],
        geo_subject:  mdata[:geographic_subject]
      }
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
        local_identifier: File.basename(dir),
        language: [find_term(code: mods_doc.language.first, vocab: "LAE Languages")],
        geographic_origin: [find_term(label: mods_doc.geographic_origin.first, vocab: "LAE Areas")],
        geo_subject: [find_term(label: mods_doc.geographic_subject.first, vocab: "LAE Areas")],
        height: height_from_extent,
        width: width_from_extent,
        page_count: page_count
      }
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

    # change this to do dir on tif, jpg, jpeg, png and create Ingestables therefrom
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

    def csv_file
      IngestableFile.new(
        file_path: mdata,
        mime_type: "text/csv",
        original_filename: File.basename(mods),
        copyable: true
      )
    end
end
