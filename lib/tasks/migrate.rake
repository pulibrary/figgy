# frozen_string_literal: true
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
      cs = DynamicChangeSet.new(resource)
      cs.prepopulate!
      logger.info "Migrating folders within the box #{resource.id}..."
      change_set_persister.save(change_set: cs)
    end
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

            child_change_set = DynamicChangeSet.new(child)
            child_change_set.prepopulate!
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
