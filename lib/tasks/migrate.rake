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

  desc "Migrated Ephemera Folders in Ephemera Boxes published in production to a completed workflow state"
  task ephemera_folders: :environment do
    # Ensures that all member EphemeraFolders have their state properly updated
    resources.each do |resource|
      cs = DynamicChangeSet.new(resource)
      cs.prepopulate!
      logger.info "Migrating folders within the box #{resource.id}..."
      change_set_persister.save(change_set: cs)
    end
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
        metadata_adapter: Valkyrie.config.metadata_adapter,
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end

    # Retrieves the query service from the metadata adapter
    # @return [Valkyrie::Persistence::Postgres::QueryService]
    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    # Retrieves the model for the resource being updated during the migration
    # @return [Class]
    def model
      EphemeraBox
    end

    # Retrieves all of the resources being updated during the migration
    # @return [Enumerable<Valkyrie::Resource>]
    def resources
      query_service.find_all_of_model(model: model)
    end
end
