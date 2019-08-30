# frozen_string_literal: true
class MissingThumbnailJob < ApplicationJob
  # Sets the thumbnail ID for a repository resource missing a thumbnail
  # @param id [String] the ID for the repository resource
  def perform(id)
    resource = metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(id))

    return resource unless resource.thumbnail_id.nil?

    member_thumbnail_ids = member_thumbnail_ids_for(resource)
    if member_thumbnail_ids.empty?
      logger.warn "Failed to locate a thumbnail for #{id}"
      return resource
    end
    new_thumbnail_id = member_thumbnail_ids.first

    resource.thumbnail_id = new_thumbnail_id
    change_set = ChangeSet.for(resource)
    updated_resource = change_set_persister.save(change_set: change_set)
    logger.info "Linked the missing thumbnail for #{updated_resource.id}"
    updated_resource
  end

  private

    # Recursively retrieve all thumbnail IDs for a given repository resource from its members
    # (This shall halt recursing if a thumbnail ID is found for a member resource)
    # @param resource [Resource] the repository resource
    # @return [Array<Valkyrie::ID>] the array of thumbnail IDs
    def member_thumbnail_ids_for(resource)
      return [] if resource.member_ids.empty?
      members = metadata_adapter.query_service.find_members(resource: resource)
      thumbnail_ids = members.to_a.map(&:thumbnail_id).reject(&:nil?)
      thumbnail_ids += members.map { |member| member_thumbnail_ids(member) } if thumbnail_ids.empty?
      thumbnail_ids.flatten
    end

    # Retrieve the metadata adapter for repository metadata
    # @return [Valkyrie::MetadataAdapter]
    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    # Retrieve the change set persister for repository resources
    # @return [ChangeSetPersister]
    def change_set_persister
      ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter)
    end
end
