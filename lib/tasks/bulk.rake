# frozen_string_literal: true
namespace :bulk do
  desc "Ingest a directory of TIFFs as a ScannedResource, or a directory of directories as a MultiVolumeWork"
  task ingest: :environment do
    user = User.find_by_user_key(ENV["USER"]) if ENV["USER"]
    user = User.all.select(&:admin?).first unless user
    dir = ENV["DIR"]
    bib = ENV["BIB"]
    coll = ENV["COLL"]
    local_id = ENV["LOCAL_ID"]
    replaces = ENV["REPLACES"]
    background = ENV["BACKGROUND"]
    model = ENV["MODEL"]

    abort "usage: rake bulk:ingest DIR=/path/to/files BIB=1234567 COLL=collid LOCAL_ID=local_id REPLACES=replaces MODEL=ResourceClass" unless dir && Dir.exist?(dir)

    @logger = Logger.new(STDOUT)
    @logger.warn "No BIB id specified" unless bib
    @logger.info "ingesting files from: #{dir}"
    @logger.info "ingesting as: #{user.user_key} (override with USER=foo)"
    @logger.info "adding item to collection #{coll}" if coll
    if model
      begin
        model.constantize
        class_name = model
      rescue
        @logger.error "Invalid model specified: #{model}.  Using ScannedResource as the default."
        class_name = "ScannedResource"
      end
    else
      class_name = "ScannedResource"
    end

    begin
      if background
        IngestFolderJob.set(queue: :low).perform_later(
          directory: dir,
          class_name: class_name,
          member_of_collection_ids: [coll],
          source_metadata_identifier: bib,
          local_identifier: local_id,
          replaces: replaces
        )
      else
        IngestFolderJob.perform_now(
          directory: dir,
          class_name: class_name,
          member_of_collection_ids: [coll],
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
    user = User.find_by_user_key(ENV["USER"]) if ENV["USER"]
    user = User.all.select(&:admin?).first unless user
    dir = ENV["DIR"]
    bib = ENV["BIB"]
    background = ENV["BACKGROUND"]

    abort "usage: rake bulk:ingest_scanned_maps BIB=1234567 DIR=/path/to/files" unless dir && Dir.exist?(dir)

    @logger = Logger.new(STDOUT)
    @logger.warn "No BIB id specified" unless bib
    @logger.info "ingesting files from: #{dir}"
    @logger.info "ingesting as: #{user.user_key} (override with USER=foo)"

    begin
      if background
        IngestMapFolderJob.set(queue: :low).perform_later(
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

  desc "Link resources to thumbnails (if they should be missing them)"
  task link_missing_thumbnails: :environment do
    background = ENV["BACKGROUND"]
    model = ENV["MODEL"]

    @logger = Logger.new(STDOUT)
    query = FindMissingThumbnailResources.new(query_service: Valkyrie::MetadataAdapter.find(:index_solr).query_service)
    resources = if model.present?
                  @logger.info "linking missing thumbnails for #{model.to_s.titleize}"
                  query.find_missing_thumbnail_resources(model: model)
                else
                  @logger.info "linking missing thumbnails for Scanned Resources"
                  query.find_missing_thumbnail_resources
                end
    resources.each do |resource|
      begin
        if background
          MissingThumbnailJob.set(queue: :low).perform_later(resource.id)
        else
          MissingThumbnailJob.perform_now(resource.id)
        end
      rescue => e
        @logger.error "Error: #{e.message}"
        @logger.error e.backtrace
      end
    end
  end

  desc "Link resources to thumbnails (if they use invalid values for thumbnail IDs)"
  task link_invalid_thumbnails: :environment do
    background = ENV["BACKGROUND"]
    model = ENV["MODEL"]

    @logger = Logger.new(STDOUT)
    query = FindInvalidThumbnailResources.new(query_service: Valkyrie::MetadataAdapter.find(:index_solr).query_service)
    resources = if model.present?
                  @logger.info "linking thumbnails for #{model.to_s.titleize}"
                  query.find_invalid_thumbnail_resources(model: model)
                else
                  @logger.info "linking thumbnails for Scanned Resources"
                  query.find_invalid_thumbnail_resources
                end
    # Handle these cases as if they were missing thumbnails
    resources.each do |resource|
      begin
        if background
          MissingThumbnailJob.set(queue: :low).perform_later(resource.id)
        else
          MissingThumbnailJob.perform_now(resource.id)
        end
      rescue => e
        @logger.error "Error: #{e.message}"
        @logger.error e.backtrace
      end
    end
  end

  desc "Attach a set of directories of TIFFs to existing objects, using the directory names as identifiers to find the objects"
  task attach_each_dir: :environment do
    user = User.find_by_user_key(ENV["USER"]) if ENV["USER"]
    user = User.all.select(&:admin?).first unless user
    dir = ENV["DIR"]
    field = ENV["FIELD"]
    filter = ENV["FILTER"]
    background = ENV["BACKGROUND"]
    model = ENV["MODEL"]
    change_set = ENV["CHANGE_SET"] || "DynamicChangeSet"

    abort "usage: rake bulk:attach_each_dir DIR=/path/to/files FIELD=barcode FILTER=filter MODEL=ResourceClass CHANGE_SET=DynamicChangeSet" unless field && dir && Dir.exist?(dir)

    @logger = Logger.new(STDOUT)
    @logger.info "attaching files from: #{dir}"
    @logger.info "attaching as: #{user.user_key} (override with USER=foo)"
    @logger.info "filtering to files ending with #{filter}" if filter
    if model
      begin
        model.constantize
        class_name = model
      rescue
        @logger.error "Invalid model specified: #{model}.  Using ScannedResource as the default."
        class_name = "ScannedResource"
      end
    else
      class_name = "ScannedResource"
    end

    begin
      if background
        IngestFoldersJob.set(queue: :low).perform_later(
          directory: dir,
          class_name: class_name,
          property: field,
          file_filter: filter,
          change_set_class: change_set
        )
      else
        IngestFoldersJob.perform_now(
          directory: dir,
          class_name: class_name,
          property: field,
          file_filter: filter,
          change_set_class: change_set
        )
      end
    rescue => e
      @logger.error "Error: #{e.message}"
      @logger.error e.backtrace
    end
  end

  desc "Update all members of a Collection to the specified state"
  task update_state: :environment do
    coll = ENV["COLL"]
    state = ENV["STATE"]

    abort "usage: rake bulk:update_sate COLL=[collection id] STATE=[state]" unless coll
    logger = Logger.new(STDOUT)
    UpdateState.perform(collection_id: Valkyrie::ID.new(coll), state: state, metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister), logger: logger)
  end

  desc "Ingest a directory of TIFFs as intermediate files for existing ScannedResources"
  task ingest_intermediate_files: :environment do
    logger = Logger.new(STDOUT)

    begin
      dir = ENV["DIR"]
      property = ENV["PROPERTY"] ? ENV["PROPERTY"].to_sym : :source_metadata_identifier
      background = ENV["BACKGROUND"].casecmp("true").zero? if ENV["BACKGROUND"]

      abort "usage: rake bulk:ingest_intermediate_files DIR=/path/to/files [PROPERTY=source_metadata_identifier] [BACKGROUND=TRUE]" unless dir && Dir.exist?(dir)

      logger.info "ingesting files from: #{dir}"

      service = BulkIngestIntermediateService.new(
        property: property,
        background: background,
        logger: logger
      )
      service.ingest(dir)
    rescue => e
      logger.error "Error: #{e.message}"
      logger.error e.backtrace
    end
  end
end
