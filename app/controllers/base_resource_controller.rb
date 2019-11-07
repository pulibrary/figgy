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
    @change_set ||= ChangeSet.for(resource)
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
    @change_set = ChangeSet.for(resource, change_set_param: change_set_param)
    parent_resource = find_resource(parent_resource_params[:id])
    authorize! :update, parent_resource

    parent_change_set = ChangeSet.for(parent_resource)
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
    @change_set = ChangeSet.for(resource)
    parent_resource = find_resource(parent_resource_params[:id])
    authorize! :update, parent_resource

    parent_change_set = ChangeSet.for(parent_resource)
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
      return {} unless params.key?("browse_everything")
      @browse_everything_params ||= params["browse_everything"]
    end

    def browse_everything_uploads
      return [] unless browse_everything_params.key?("uploads")
      @browse_everything_uploads ||= browse_everything_params["uploads"]
    end

    # Construct the pending download objects
    # @return [Array<PendingUpload>]
    def new_pending_uploads
      @new_pending_uploads ||= begin
        browse_everything_uploads.map do |upload_id|
          upload_files(upload_id).map do |upload_file|
            # create the pending upload
            PendingUpload.new(
              id: SecureRandom.uuid,
              upload_file_id: upload_file.id
            )
          end
        end.flatten
      end
    end

    # Load upload files, filtering out hidden files
    def upload_files(upload_id)
      # Ensure files are downloaded via ActiveStorage. We disable this in
      # BrowseEverything via overriding BrowseEverything::Upload#perform_job so
      # that the slow processing happens in our controllers where we can either
      # not do it (in BulkIngest), or optimize it if possible later.
      BrowseEverything::UploadJob.perform_now(upload_id: upload_id)
      # This needs to be changed to #find_one
      BrowseEverything::Upload.find_by(uuid: upload_id).first.files.select do |upload_file|
        !(upload_file.name =~ /^\./)
      end
    end
end
