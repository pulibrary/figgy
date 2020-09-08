# frozen_string_literal: true
require "find"

namespace :migrate do
  desc "Migrate users in group image_editor to group staff"
  task image_editor: :environment do
    staff = Role.where(name: "staff").first_or_create

    User.all.select { |u| u.roles.map(&:name).include?("image_editor") }.each do |u|
      u.roles = u.roles.select { |role| role.name != "image_editor" }
      u.roles << staff
      u.save
    end
  end

  desc "Migrates Ephemera Folders in Ephemera Boxes published in production to a completed workflow state"
  task ephemera_folders: :environment do
    resources(model: EphemeraFolder).each do |resource|
      cs = ChangeSet.for(resource)
      logger.info "Migrating folders within the box #{resource.id}..."
      change_set_persister.save(change_set: cs)
    end
  end

  desc "Migrates Ukrainian Ephemera Folders from MODS metadata records"
  task ukrainian_ephemera_mods: :environment do
    project = ENV["PROJECT"]
    mods = ENV["MODS"]
    dir = ENV["DIR"]

    usage = "usage: rake migrate:ukrainian_ephemera_mods PROJECT=project_id MODS=/path/to/metadata.mods DIR=/path/to/files"
    abort usage unless project && dir && mods && Dir.exist?(dir) && File.exist?(mods)
    IngestUkrainianEphemeraMODSJob.set(queue: :low).perform_now(project, mods, dir)
  end

  desc "Migrates directory of GNIB records"
  task gnib_directory: :environment do
    project = ENV["PROJECT"]
    md_root = ENV["METADATA"]
    image_root = ENV["IMAGES"]

    usage = "usage: rake migrate:gnib_directory PROJECT=project_id METADATA=/path/to/mods_records IMAGES=/path/to/images"
    abort usage unless project && image_root && md_root && Dir.exist?(image_root) && Dir.exist?(md_root)
    logger.info "Ingesting GNIB records from #{md_root}"
    change_set_persister = ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
    output = nil

    Find.find(md_root) do |md_path|
      next unless File.basename(md_path) =~ /mods$/
      subdir_name = File.dirname(md_path).match(/^.*pudl0066\/(.*)$/)[1]
      image_path = File.join(image_root, subdir_name, File.basename(md_path, ".*"))
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        output = IngestEphemeraMODS::IngestGnibMODS.new(project, md_path, image_path, buffered_changeset_persister, logger).ingest
      end
      logger.info "Imported #{md_path} from pulstore: #{output.id}"
    end
  end

  desc "Migrates directory of Moscow Election records"
  task gnib_directory: :environment do
    project = ENV["PROJECT"]
    md_root = ENV["METADATA"]
    image_root = ENV["IMAGES"]

    usage = "usage: rake migrate:gnib_directory PROJECT=project_id METADATA=/path/to/mods_records IMAGES=/path/to/images"
    abort usage unless project && image_root && md_root && Dir.exist?(image_root) && Dir.exist?(md_root)
    logger.info "Ingesting Moscow election records from #{md_root}"
    change_set_persister = ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
    output = nil

    Find.find(md_root) do |md_path|
      next unless File.basename(md_path) =~ /mods$/
      subdir_name = File.dirname(md_path).match(/^.*pudl0125\/(.*)$/)[1]
      image_path = File.join(image_root, subdir_name, File.basename(md_path, ".*"))
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        output = IngestEphemeraMODS::IngestGnibMODS.new(project, md_path, image_path, buffered_changeset_persister, logger).ingest
      end
      logger.info "Imported #{md_path} from pulstore: #{output.id}"
    end
  end

  desc "Migrates a single MODS and images"
  task gnib_single_record: :environment do
    project = ENV["PROJECT"]
    mods = ENV["MODS"]
    dir = ENV["DIR"]

    usage = "usage: rake migrate:gnib_single_record PROJECT=project_id MODS=/path/to/metadata.mods DIR=/path/to/files"
    abort usage unless project && dir && mods && Dir.exist?(dir) && File.exist?(mods)
    IngestGnibMODSJob.set(queue: :low).perform_now(project, mods, dir)
  end

  desc "Migrates Collection members with children who have values in the member_of_collection_ids attribute"
  task collection_members_with_children: :environment do
    resources(model: Collection).each do |collection|
      logger.info "Migrating Collection members for #{collection.id}..."

      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        collection.decorate.members.each do |collection_member|
          collection_member.decorate.members.each do |child|
            next if !child.respond_to?(:member_of_collection_ids) || child.member_of_collection_ids.empty?

            logger.info "Migrating the collections for member resource #{child.id}..."

            child_change_set = ChangeSet.for(child)
            child_change_set.validate(member_of_collection_ids: [])

            buffered_change_set_persister.save(change_set: child_change_set)
          end
        end
      end
    end
  end

  desc "populate archival_collection_code field from source_metadata_identifier"
  task archival_collection_code: :environment do
    ExtractArchivalCollectionCodeJob.perform_now
  end

  desc "Fix email addresses created with extra @princeton.edu appended to external email addresses"
  task fix_external_emails: :environment do
    User.where("email like '%@%@%'").each do |u|
      u.email.gsub!(/@princeton.edu$/, "")
      u.save!
    end
  end

  desc "update all local identifiers starting with `cico:` to start with `dcl:`"
  task cico_ids: :environment do
    coll = ENV["COLL"]
    abort "usage: rake migrate:cico_ids COLL=[collection id]" unless coll
    UpdateCicoIdsJob.perform_now(collection_id: coll)
  end

  desc "Update all Recordings and Playlists to have downloadable: none"
  task recordings_undownloadable: :environment do
    RecordingDownloadableMigrator.call
  end

  desc "Add FileMetadata IDs to PreservationObjects"
  task preservation_object_file_metadata_ids: :environment do
    AddPreservationObjectIdsMigrator.call
  end

  desc "Add cached parent IDs to all non-filesets"
  task cached_parent_ids: :environment do
    Migrations::AddCachedParentIdsMigrator.call
  end

  private

    # Construct or retrieve the memoized logger for STDOUT
    # @return [Logger]
    def logger
      @logger ||= Logger.new(STDOUT)
    end

    # Construct a ChangeSetPersister for persisting the EphemeraBoxes and member EphemeraFolders
    # @return [ChangeSetPersister]
    def change_set_persister
      ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end

    # Retrieves the query service from the metadata adapter
    # @return [Valkyrie::Persistence::Postgres::QueryService]
    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    # Retrieves all of the resources being updated during the migration
    # @return [Enumerable<Valkyrie::Resource>]
    def resources(model:)
      query_service.find_all_of_model(model: model)
    end
end
