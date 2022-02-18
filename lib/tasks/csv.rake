# frozen_string_literal: true

require "csv"

#
# These tasks are designed to be used when employing a spreadsheet of
# metadata to import ephemera materials into Figgy.
#
namespace :figgy do
  namespace :csv do
    desc "ingest ephemera from a csv file"
    task ingest_ephemera: :environment do
      basedir = ENV["BASEDIR"]
      csvfile = ENV["CSV"]
      project_id = ENV["PROJECT"]

      abort "usage: BASEDIR=directory CSV=csvfile PROJECT=project_id rake csv:ingest_ephemera" unless basedir && project_id && csvfile
      abort "no such file #{csvfile}" unless File.file?(csvfile)
      abort "no such directory #{basedir}" unless File.directory?(basedir)
      @logger = Logger.new($stdout)

      @logger.info "beginning to ingest ephemera from #{csvfile} with basedir #{basedir}"
      IngestEphemeraCSVJob.perform_now(project_id, csvfile, basedir)
      @logger.info "finished ingesting ephemera"
    end

    desc "Ingest resources from a csv file"
    task ingest_resources: :environment do
      basedir = ENV["BASEDIR"]
      coll = ENV["COLL"]
      csvfile = ENV["CSV"]

      abort "usage: COLL=collection_id BASEDIR=directory CSV=csvfile rake bulk:ingest_resources" unless coll && basedir
      abort "no such file #{csvfile}" unless File.file?(csvfile)
      abort "no such directory #{basedir}" unless File.directory?(basedir)
      abort "usage: COLL=collection_id BASEDIR=directory CSV=csvfile rake bulk:from_csv" unless coll && basedir
      abort "no such file #{csvfile}" unless File.file?(csvfile)
      class_name = "ScannedResource"
      @logger = Logger.new($stdout)

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
        filters = [".jpg", ".png", ".tif", ".TIF", ".tiff", ".TIFF"]
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
end
