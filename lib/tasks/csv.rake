# frozen_string_literal: true
require "csv"

=begin

These tasks are designed to be used when employing a spreadsheet of
metadata to import ephemera materials into Figgy.

=end

namespace :csv do

  desc "ingest ephemera from a csv file"
  task ingest_ephemera: :environment do
    basedir = ENV["BASEDIR"]
    input_project_id = ENV["PROJECT"]
    csvfile = ENV["CSV"]

    abort "usage: PROJECT=project_id BASEDIR=directory CSV=csvfile rake csv:ingest_ephemera" unless input_project_id && basedir
    abort "no such file #{csvfile}" unless File.file?(csvfile)
    class_name = "ScannedResource"
    @logger = Logger.new(STDOUT)

    qs = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    project = qs.find_by(id: input_project_id)

    abort "no such project" unless project

    change_set_persister = ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy))

    @logger.info "beginning to ingest ephemera into #{project.title} from #{csvfile} with basedir #{basedir}"
    IngestEphemeraCSVJob.perform_now(project.id, csvfile, basedir)
    @logger.info "finished ingesting ephemera"
  end

  desc "Ingest resources from a csv file"
  task from_csv: :environment do
    basedir = ENV["BASEDIR"]
    coll = ENV["COLL"]
    csvfile = ENV["CSV"]

    abort "usage: COLL=collection_id BASEDIR=directory CSV=csvfile rake bulk:from_csv" unless coll && basedir
    abort "no such file #{csvfile}" unless File.file?(csvfile)
    class_name = "ScannedResource"
    @logger = Logger.new(STDOUT)

    begin
      csv = CSV.read(csvfile, headers: true)
    rescue => e
      @logger.error "Error: #{e.message}"
      @logger.error e.backtrace
    end

    logger.info "processing #{csv.length} rows"
    csv.each do |row|
      logger.info "processing #{row}"
      attrs = row.map { |k, v| [k.to_sym, v] }.to_h
      dir = File.join(basedir, attrs.delete(:path))
      filters = [".jpg", ".png"]
      IngestFolderJob.perform_now(
        directory: dir,
        class_name: class_name,
        member_of_collection_ids: [coll],
        file_filters: filters,
        **attrs
      )
      @logger.info "Processd row #{row} --- dir: #{dir}; class_name: #{class_name}; file_filters: #{filters}; attributes: #{attrs}"      
    end
  end
end
