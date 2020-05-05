# frozen_string_literal: true

# A base controller for resources, intended for inheritance
class BaseResourceController < ApplicationController
  include ResourceController
  include TokenAuth
  before_action :load_collections, only: [:new, :edit, :update, :create]

  def load_collections
    @collections = query_service.find_all_of_model(model: Collection).map(&:decorate) || []
  end

  def resource
    find_resource(params[:id])
  end

  def change_set
    @change_set ||= change_set_class.new(resource)
  end

  # Resources that allow uploads will use these browse everything methods
  def browse_everything_files
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      change_set.validate(pending_uploads: change_set.pending_uploads + new_pending_uploads, files: new_pending_uploads)
      buffered_changeset_persister.save(change_set: change_set)
    end

    redirect_to ContextualPath.new(child: resource, parent_id: nil).file_manager
  end

  # Attach a resource to a parent
  def attach_to_parent
    @change_set = change_set_class.new(find_resource(params[:id]))
    parent_resource = find_resource(parent_resource_params[:id])
    authorize! :update, parent_resource

    parent_change_set = DynamicChangeSet.new(parent_resource)
    if parent_change_set.validate(parent_resource_params)
      current_member_ids = parent_resource.member_ids
      attached_member_ids = parent_change_set.member_ids
      parent_change_set.member_ids = current_member_ids + attached_member_ids
      obj = nil
      change_set_persister.buffer_into_index do |persist|
        obj = persist.save(change_set: parent_change_set)
      end
      after_update_success(obj, @change_set)
    else
      after_update_failure
    end
  rescue Dry::Types::ConstraintError
    after_update_failure
  rescue Valkyrie::Persistence::ObjectNotFoundError => e
    after_update_error e
  end

  # Remove a resource from a parent
  def remove_from_parent
    @change_set = change_set_class.new(find_resource(params[:id]))
    parent_resource = find_resource(parent_resource_params[:id])
    authorize! :update, parent_resource

    parent_change_set = DynamicChangeSet.new(parent_resource)
    if parent_change_set.validate(parent_resource_params)
      current_member_ids = parent_resource.member_ids
      removed_member_ids = parent_change_set.member_ids
      parent_change_set.member_ids = current_member_ids - removed_member_ids

      obj = nil
      change_set_persister.buffer_into_index do |persist|
        obj = persist.save(change_set: parent_change_set)
      end
      after_update_success(obj, @change_set)
    else
      after_update_failure
    end
  rescue Dry::Types::ConstraintError
    after_update_failure
  rescue Valkyrie::Persistence::ObjectNotFoundError => e
    after_update_error e
  end

  private

    def parent_resource_params
      params[:parent_resource].to_unsafe_h
    end

    def browse_everything_params
      @browse_everything_params ||= params["browse_everything"]
    end

    def browse_everything_uploads
      @browse_everything_uploads ||= browse_everything_params["uploads"]
    end

    # Construct the pending download objects
    # @return [Array<PendingUpload>]
    def new_pending_uploads
      @new_pending_uploads = []

      browse_everything_uploads.each do |upload_id|
        # This needs to be changed to #find_one
        uploads = BrowseEverything::Upload.find_by(uuid: upload_id)
        upload = uploads.first

        upload.files.each do |upload_file|
          new_pending_upload = PendingUpload.new(
            id: SecureRandom.uuid,
            upload_file_id: upload_file.id
          )
          @new_pending_uploads << new_pending_upload
        end
      end

      @new_pending_uploads
    end
end
