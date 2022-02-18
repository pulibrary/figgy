# frozen_string_literal: true

namespace :figgy do
  namespace :bulk do
    desc "Migrates directory of METS files"
    task ingest_mets: :environment do
      md_root = ENV["METADATA"]
      import_mods = ENV["IMPORT_MODS"]&.casecmp("TRUE")&.zero?
      user = User.find_by_user_key(ENV["USER"]) if ENV["USER"]
      user ||= User.all.select(&:admin?).first

      usage = "usage: rake bulk:ingest_mets METADATA=/path/to/mets_records IMPORT_MODS=TRUE USER=user"
      abort usage unless md_root && Dir.exist?(md_root)
      logger.info "Ingesting METS records from #{md_root}"

      Find.find(md_root) do |md_path|
        logger.info "Importing #{md_path} with user=#{user} and import_mods=#{import_mods}"
        if File.file?(md_path)
          IngestMETSJob.perform_now(md_path, user, import_mods)
          logger.info "Imported #{md_path}"
        end
      end
    end

    desc "Re-apply METS metadata to objects in a collection"
    task reprocess_mets: :environment do
      collection_id = ENV["COLL"]

      abort "usage: rake bulk:reprocess_mets COLL=collid" unless collection_id
      ReprocessMetsJob.set(queue: :low).perform_later(collection_id: collection_id)
    end

    desc "Refreshes remote metadata for everything"
    task refresh_remote_metadata: :environment do
      batch_size = ENV["BATCH_SIZE"] || 50

      @logger = Logger.new(STDOUT)
      @logger.info "Generating background jobs to refresh remote metadata for everything:"
      BulkUpdateRemoteMetadataService.call(batch_size: batch_size)
    end

    desc "Ingest a directory of TIFFs as a ScannedResource, or a directory of directories as a MultiVolumeWork"
    task ingest: :environment do
      user = User.find_by_user_key(ENV["USER"]) if ENV["USER"]
      user ||= User.all.select(&:admin?).first
      dir = ENV["DIR"]
      bib = ENV["BIB"]
      coll = ENV["COLL"]
      local_id = ENV["LOCAL_ID"]
      replaces = ENV["REPLACES"]
      background = ENV["BACKGROUND"]
      model = ENV["MODEL"]
      filter = ENV["FILTER"]
      identifier = ENV["OBJID"] # will be the ark for the resource
      title = ENV["TITLE"]
      note = ENV["NOTE"]

      abort "usage: rake bulk:ingest DIR=/path/to/files BIB=1234567 COLL=collid LOCAL_ID=local_id REPLACES=replaces FILTER=file_filter MODEL=ResourceClass" unless dir && Dir.exist?(dir)

      @logger = Logger.new(STDOUT)
      @logger.warn "No BIB id specified" unless bib
      @logger.info "ingesting files from: #{dir}"
      @logger.info "filtering to files ending with #{filter}" if filter
      @logger.info "ingesting as: #{user.user_key} (override with USER=foo)"
      @logger.info "adding item to collection #{coll}" if coll
      @logger.info "passing identifier |#{identifier}|"
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
            file_filters: [filter],
            member_of_collection_ids: [coll],
            source_metadata_identifier: bib,
            local_identifier: local_id,
            replaces: replaces,
            identifier: identifier,
            title: title,
            portion_note: note
          )
        else
          IngestFolderJob.perform_now(
            directory: dir,
            class_name: class_name,
            file_filters: [filter],
            member_of_collection_ids: [coll],
            source_metadata_identifier: bib,
            local_identifier: local_id,
            replaces: replaces,
            identifier: identifier,
            title: title,
            portion_note: note
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
      user ||= User.all.select(&:admin?).first
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
      query = Valkyrie::MetadataAdapter.find(:index_solr).query_service.custom_queries
      resources = if model.present?
        @logger.info "linking missing thumbnails for #{model.to_s.titleize}"
        query.find_missing_thumbnail_resources(model: model)
      else
        @logger.info "linking missing thumbnails for Scanned Resources"
        query.find_missing_thumbnail_resources
      end
      resources.each do |resource|
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

    desc "Link resources to thumbnails (if they use invalid values for thumbnail IDs)"
    task link_invalid_thumbnails: :environment do
      background = ENV["BACKGROUND"]
      model = ENV["MODEL"]

      @logger = Logger.new(STDOUT)
      query = Valkyrie::MetadataAdapter.find(:index_solr).query_service.custom_queries
      resources = if model.present?
        @logger.info "linking thumbnails for #{model.to_s.titleize}"
        query.find_invalid_thumbnail_resources(model: model)
      else
        @logger.info "linking thumbnails for Scanned Resources"
        query.find_invalid_thumbnail_resources
      end
      # Handle these cases as if they were missing thumbnails
      resources.each do |resource|
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

    desc "Attach a set of directories of TIFFs to existing objects, using the directory names as identifiers to find the objects"
    task attach_each_dir: :environment do
      user = User.find_by_user_key(ENV["USER"]) if ENV["USER"]
      user ||= User.all.select(&:admin?).first
      dir = ENV["DIR"]
      field = ENV["FIELD"]
      filter = ENV["FILTER"]
      background = ENV["BACKGROUND"]
      model = ENV["MODEL"]
      change_set_name = ENV["CHANGE_SET_NAME"]

      abort "usage: rake bulk:attach_each_dir DIR=/path/to/files FIELD=barcode FILTER=filter MODEL=ResourceClass CHANGE_SET_NAME=simple" unless field && dir && Dir.exist?(dir)

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
            file_filters: [filter],
            change_set_param: change_set_name
          )
        else
          IngestFoldersJob.perform_now(
            directory: dir,
            class_name: class_name,
            property: field,
            file_filters: [filter],
            change_set_param: change_set_name
          )
        end
      rescue => e
        @logger.error "Error: #{e.message}"
        @logger.error e.backtrace
      end
    end

    desc "Update all members of a Collection to the specified state and/or rights statement"
    task update_attrs: :environment do
      coll = ENV["COLL"]
      state = ENV["STATE"]
      rights = ENV["RIGHTS"]
      preservation_policy = ENV["PRESERVATION_POLICY"]

      abort "usage: rake bulk:update_attrs COLL=[collection id] STATE=[state] RIGHTS=[rights] PRESERVATION_POLICY=[cloud]" unless coll
      logger = Logger.new(STDOUT)
      attrs = {}
      attrs[:state] = state if state
      attrs[:rights_statement] = rights if rights
      attrs[:preservation_policy] = preservation_policy if preservation_policy
      BulkEditService.perform(collection_id: Valkyrie::ID.new(coll), attributes: attrs, metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister), logger: logger)
    end

    # Intermediate files were created to add watermarks
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

    desc "Remove all resources in an archival collection"
    task remove: :environment do
      abort "usage: rake bulk:remove CODE=archival_collection_code" unless ENV["CODE"]

      archival_collection_code = ENV["CODE"]
      background = ENV["BACKGROUND"]

      @logger = Logger.new(STDOUT)
      @logger.info "Removing archival collection #{archival_collection_code}"

      begin
        if background
          DeleteArchivalCollectionJob.set(queue: :low).perform_later(id: archival_collection_code)
        else
          DeleteArchivalCollectionJob.perform_now(id: archival_collection_code)
        end
      rescue => e
        @logger.error "Error: #{e.message}"
      end
    end

    desc "Adds all members of a Collection to an additional collection"
    task append_coll: :environment do
      coll = ENV["COLL"]
      append_coll = ENV["APPEND_COLL"]

      abort "usage: rake bulk:append_coll COLL=[collection id] APPEND_COLL=[new collection id]" unless coll && append_coll
      logger = Logger.new(STDOUT)
      attrs = {append_collection_ids: Valkyrie::ID.new(append_coll), skip_validation: true}
      BulkEditService.perform(collection_id: Valkyrie::ID.new(coll), attributes: attrs, metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister), logger: logger)
    end

    desc "Adds EphemeraFolders from an EphemeraProject to a Collection"
    task add_ephemera_to_collection: :environment do
      project_id = ENV["PROJECT"]
      collection_id = ENV["COLL"]
      abort "usage: rake bulk:ephemera_add_to_collection PROJECT=project_id COLL=collection_id" unless project_id && collection_id

      AddEphemeraToCollectionJob.perform_now(project_id, collection_id)
      logger.info "Added ephemera from #{project_id} to collection #{collection_id}"
    end

    desc "adds blank barcode to everything"
    task add_barcodes: :environment do
      project_id = ENV["PROJECTID"]
      abort "usage rake bulk:add_barcodes PROJECTID=projectid" unless project_id

      change_set_persister = ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
      )
      qs = Valkyrie.config.metadata_adapter.query_service
      project = qs.find_by(id: project_id)
      abort "no project found" unless project
      Wayfinder.for(project).members.each do |folder|
        logger.info "processing #{folder.id}"
        cs = BoxlessEphemeraFolderChangeSet.new(folder)
        cs.validate(barcode: "0000000000")
        change_set_persister.save(change_set: cs)
      end
    end

    desc "Delete all members of a collection, keeping the collection"
    task clear: :environment do
      id = ENV["ID"]
      abort "usage: rake bulk:clear ID=collectionid" unless id

      metadata_adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      qs = metadata_adapter.query_service
      change_set_persister = ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter)
      amc = qs.find_by(id: id)
      amc_wayfinder = Wayfinder.for(amc)
      amc_wayfinder.members.each { |member| change_set_persister.delete(change_set: ChangeSet.for(member)) }
    end
  end
end
