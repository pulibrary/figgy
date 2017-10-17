# frozen_string_literal: true
namespace :bulk do
  desc "Ingest a directory of TIFFs as a ScannedResource, or a directory of directories as a MultiVolumeWork"
  task ingest: :environment do
    user = User.find_by_user_key(ENV['USER']) if ENV['USER']
    user = User.all.select(&:admin?).first unless user
    dir = ENV['DIR']
    bib = ENV['BIB']
    coll = ENV['COLL']
    local_id = ENV['LOCAL_ID']
    replaces = ENV['REPLACES']
    background = ENV['BACKGROUND']

    abort "usage: rake bulk:ingest DIR=/path/to/files BIB=1234567 COLL=collid LOCAL_ID=local_id REPLACES=replaces" unless dir && Dir.exist?(dir)

    if coll.present?
      query = FindByTitle.new(query_service: Valkyrie.config.metadata_adapter.query_service)
      collection = query.find_by_title(title: coll)
    end

    @logger = Logger.new(STDOUT)
    @logger.warn "No BIB id specified" unless bib
    @logger.info "ingesting files from: #{dir}"
    @logger.info "ingesting as: #{user.user_key} (override with USER=foo)"
    @logger.info "adding item to collection #{coll}" if coll

    begin
      if background
        IngestFolderJob.perform_later(
          directory: dir,
          collection: collection,
          source_metadata_identifier: bib,
          local_identifier: local_id,
          replaces: replaces
        )
      else
        IngestFolderJob.perform_now(
          directory: dir,
          collection: collection,
          source_metadata_identifier: bib,
          local_identifier: local_id,
          replaces: replaces
        )
      end
    rescue => e
      @logger.error "Error: #{e.message}"
      @logger.error e.backtrace
    end
  end

  desc "Ingest a directory of scanned map TIFFs, each filename corresponds to a Bib ID"
  task ingest_scanned_maps: :environment do
    user = User.find_by_user_key(ENV['USER']) if ENV['USER']
    user = User.all.select(&:admin?).first unless user
    dir = ENV['DIR']
    bib = ENV['BIB']
    background = ENV['BACKGROUND']

    abort "usage: rake bulk:ingest_scanned_maps BIB=1234567 DIR=/path/to/files" unless dir && Dir.exist?(dir)

    @logger = Logger.new(STDOUT)
    @logger.warn "No BIB id specified" unless bib
    @logger.info "ingesting files from: #{dir}"
    @logger.info "ingesting as: #{user.user_key} (override with USER=foo)"

    begin
      if background
        IngestMapFolderJob.perform_later(
          directory: dir,
          source_metadata_identifier: bib
        )
      else
        IngestMapFolderJob.perform_now(
          directory: dir,
          source_metadata_identifier: bib
        )
      end
    rescue => e
      @logger.error "Error: #{e.message}"
      @logger.error e.backtrace
    end
  end

  desc "Attach a set of directories of TIFFs to existing objects, using the directory names as identifiers to find the objects"
  task attach_each_dir: :environment do
    user = User.find_by_user_key(ENV['USER']) if ENV['USER']
    user = User.all.select(&:admin?).first unless user
    dir = ENV['DIR']
    field = ENV['FIELD']
    filter = ENV['FILTER']
    background = ENV['BACKGROUND']

    abort "usage: rake bulk:attach_each_dir DIR=/path/to/files FIELD=barcode FILTER=filter" unless field && dir && Dir.exist?(dir)

    @logger = Logger.new(STDOUT)
    @logger.info "attaching files from: #{dir}"
    @logger.info "attaching as: #{user.user_key} (override with USER=foo)"
    @logger.info "filtering to files ending with #{filter}" if filter

    begin
      if background
        IngestFoldersJob.perform_later(
          directory: dir,
          property: field,
          file_filter: filter
        )
      else
        IngestFoldersJob.perform_now(
          directory: dir,
          property: field,
          file_filter: filter
        )
      end
    rescue => e
      @logger.error "Error: #{e.message}"
      @logger.error e.backtrace
    end
  end
end
