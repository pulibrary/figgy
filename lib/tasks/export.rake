# frozen_string_literal: true
namespace :figgy do
  namespace :export do
    desc "Exports an object to disk in a BagIt bag"
    task bag: :environment do
      id = ENV["ID"]
      abort "usage: rake export:bag ID=[object id]" unless id

      ExportBagJob.perform_now(id)
    end

    desc "Exports an object to disk in a Hathi SIP"
    task hathi: :environment do
      id = ENV["ID"]
      abort "usage: rake export:hathi ID=[object id]" unless id

      ExportHathiSipJob.perform_now(id)
    end

    desc "Exports an object to files on disk"
    task files: :environment do
      ids = ENV["ID"]
      abort "usage: rake export:files ID=[object ids, comma separated]" unless ids

      @logger = Logger.new(STDOUT)
      ids.split(",").each do |id|
        logger.info "Exporting #{id} to disk"
        ExportFilesJob.perform_now(id)
      end
    end

    desc "Exports an object to files on disk"
    task pdf: :environment do
      ids = ENV["ID"]
      abort "usage: rake export:pdf ID=[object ids, comma separated]" unless ids

      @logger = Logger.new(STDOUT)
      ids.split(",").each do |id|
        logger.info "Exporting #{id} to disk as PDF"
        ExportPDFJob.perform_now(id)
      end
    end

    # Part of the process of exporting a finding aid to disk with local PDFs.  This task
    # exports PDFs from a collection to disk, which are then linked to using the
    # export:pulfa_pdf task.
    desc "Export PDFs for every item in a collection"
    task collection_pdf: :environment do
      colid = ENV["COLL"]
      abort "usage: rake export:collection_pdf COLL=[collection id]" unless colid
      ExportCollectionPDFJob.perform_now(colid)
    end

    desc "Exports Cicognara resource metadata to CSV"
    task cicognara: :environment do
      coll = ENV["COLL"]
      abort "usage: rake export:cicognara COLL=[collection id]" unless coll

      CSV do |csv|
        csv << CicognaraCSV.headers
        CicognaraCSV.values(coll).each do |row|
          csv << row
        end
      end
    end

    desc "Exports Cicognara resource metadata to MARC"
    task cicognara_marc: :environment do
      coll = ENV["COLL"]
      abort "usage: rake export:cicognara_marc COLL=[collection id]" unless coll
      output_dir = Rails.root.join("tmp", "cicognara_marc_output")
      Dir.mkdir output_dir unless File.directory? output_dir
      exporter = CicognaraMarc.new(cico_collection_id: coll, out_dir: output_dir)
      exporter.run
    end
  end
end
