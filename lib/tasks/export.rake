# frozen_string_literal: true
namespace :export do
  desc "Exports an object to disk in a BagIt bag"
  task bag: :environment do
    id = ENV["ID"]
    abort "usage: rake export:bag ID=[object id]" unless id

    ExportBagJob.perform_now(id)
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
