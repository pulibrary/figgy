# frozen_string_literal: true

# A base controller for resources, intended for inheritance
class BaseResourceController < ApplicationController
  include Valhalla::ResourceController
  include TokenAuth
  before_action :load_collections, only: [:new, :edit]

  def load_collections
    @collections = query_service.find_all_of_model(model: Collection).map(&:decorate)
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
      change_set.validate(pending_uploads: change_set.pending_uploads + selected_files)
      change_set.sync
      buffered_changeset_persister.save(change_set: change_set)
    end
    BrowseEverythingIngestJob.perform_later(resource.id.to_s, self.class.to_s, selected_files.map(&:id).map(&:to_s))
    redirect_to Valhalla::ContextualPath.new(child: resource, parent_id: nil).file_manager
  end

  def selected_files
    @selected_files ||= selected_file_params.values.map do |x|
      auth_header_values = x.delete("auth_header")
      auth_header = JSON.generate(auth_header_values)
      PendingUpload.new(x.symbolize_keys.merge(id: SecureRandom.uuid, created_at: Time.current.utc.iso8601, auth_header: auth_header))
    end
  end

  # Attach a resource to a parent
  def attach_to_parent
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    parent_resource = find_resource(parent_resource_params[:id])
    authorize! :update, parent_resource

    parent_change_set = DynamicChangeSet.new(parent_resource).prepopulate!
    if parent_change_set.validate(parent_resource_params)
      current_member_ids = parent_resource.member_ids
      attached_member_ids = parent_change_set.member_ids
      parent_change_set.member_ids = current_member_ids + attached_member_ids
      parent_change_set.sync
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
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    parent_resource = find_resource(parent_resource_params[:id])
    authorize! :update, parent_resource

    parent_change_set = DynamicChangeSet.new(parent_resource).prepopulate!
    if parent_change_set.validate(parent_resource_params)
      current_member_ids = parent_resource.member_ids
      removed_member_ids = parent_change_set.member_ids
      parent_change_set.member_ids = current_member_ids - removed_member_ids
      parent_change_set.sync
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

    def selected_file_params
      params[:selected_files].to_unsafe_h
    end

    def parent_resource_params
      params[:parent_resource].to_unsafe_h
    end
end
