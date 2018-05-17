# frozen_string_literal: true
module ResourceController
  extend ActiveSupport::Concern
  included do
    class_attribute :change_set_class, :resource_class, :change_set_persister
    delegate :metadata_adapter, to: :change_set_persister
    delegate :persister, :query_service, to: :metadata_adapter
    include Blacklight::SearchContext
  end

  def new
    @change_set = change_set_class.new(new_resource, append_id: params[:parent_id]).prepopulate!
    authorize! :create, resource_class
  end

  def new_resource
    resource_class.new
  end

  def create
    @change_set = change_set_class.new(resource_class.new)
    authorize! :create, @change_set.resource
    if @change_set.validate(resource_params.merge(depositor: [current_user.uid]))
      @change_set.sync
      obj = nil
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        obj = buffered_changeset_persister.save(change_set: @change_set)
      end
      after_create_success(obj, @change_set)
    else
      Rails.logger.warn(@change_set.errors.details)
      render :new
    end
  end

  def after_create_success(obj, change_set)
    redirect_to contextual_path(obj, change_set).show
  end

  def destroy
    @change_set = change_set_class.new(find_resource(params[:id]))
    authorize! :destroy, @change_set.resource
    change_set_persister.buffer_into_index do |persist|
      persist.delete(change_set: @change_set)
    end
    flash[:alert] = "Deleted #{@change_set.resource}"
    after_delete_success
  end

  def after_delete_success
    redirect_to root_path
  end

  def edit
    @change_set = change_set_class.new(find_resource(params[:id]))
    authorize! :update, @change_set.resource
    @change_set.prepopulate!
    @change_set.validate({})
  end

  def update
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :update, @change_set.resource
    if @change_set.validate(resource_params)
      @change_set.sync
      obj = nil
      change_set_persister.buffer_into_index do |persist|
        obj = persist.save(change_set: @change_set)
      end
      after_update_success(obj, @change_set)
    else
      after_update_failure
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError => e
    after_update_error e
  end

  def after_update_success(obj, change_set)
    respond_to do |format|
      format.html do
        redirect_to contextual_path(obj, change_set).show
      end
      format.json { render json: { status: "ok" } }
    end
  end

  def after_update_failure
    respond_to do |format|
      format.html { render :edit }
      format.json { head :bad_request }
    end
  end

  def after_update_error(e)
    respond_to do |format|
      format.html { raise e }
      format.json { head :not_found }
    end
  end

  def file_manager
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :file_manager, @change_set.resource
    file_set_children = query_service.find_members(resource: @change_set).select { |x| x.is_a?(FileSet) }
    @children = file_set_children.map do |x|
      change_set_class.new(x).prepopulate!
    end.to_a
  end

  def order_manager
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :order_manager, @change_set.resource
    @children = query_service.find_members(resource: @change_set).map do |x|
      change_set_class.new(x).prepopulate!
    end.to_a
  end

  def contextual_path(obj, change_set)
    ContextualPath.new(child: obj.id, parent_id: change_set.append_id)
  end

  def _prefixes
    @_prefixes ||= super + ["valhalla/base"]
  end

  def resource_params
    params[resource_class.to_s.underscore.to_sym].to_unsafe_h
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id))
  end
end
