# frozen_string_literal: true
module ResourceController
  extend ActiveSupport::Concern
  included do
    class_attribute :resource_class, :change_set_persister
    delegate :metadata_adapter, to: :change_set_persister
    delegate :persister, :query_service, to: :metadata_adapter
    include Blacklight::SearchContext
  end

  def new
    @change_set = new_change_set
    @change_set.append_id = params[:parent_id]
    @change_set.prepopulate!
    authorize! :create, resource_class
  rescue InvalidChangeSetError => e
    Valkyrie.logger.error(e.message)
    flash[:error] = "#{change_set_param} is not a valid resource type."
    redirect_to new_scanned_resource_path
  end

  # Will pass through an InvalidChangeSetError if received
  def new_change_set
    if change_set_param
      ChangeSet.class_from_param(change_set_param).new(new_resource)
    else
      ChangeSet.for(new_resource)
    end
  end

  def new_resource
    resource_class.new
  end

  def create
    @change_set = new_change_set
    authorize! :create, @change_set.resource
    if @change_set.validate(resource_params.merge(depositor: [current_user.uid]))
      @change_set.sync
      obj = nil
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        obj = buffered_changeset_persister.save(change_set: @change_set)
      end
      after_create_success(obj, @change_set)
    else
      Valkyrie.logger.warn(@change_set.errors.details)
      render :new
    end
  rescue SourceMetadataIdentifierValidator::InvalidMetadataIdentifierError => invalid_metadata_id_error
    Valkyrie.logger.error(invalid_metadata_id_error.message)
    flash[:error] = invalid_metadata_id_error.message
    render :new
  end

  def after_create_success(obj, change_set)
    redirect_to contextual_path(obj, change_set).show
  end

  def destroy
    @change_set = ChangeSet.for(find_resource(params[:id]))
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
    @change_set = ChangeSet.for(find_resource(params[:id]))
    authorize! :update, @change_set.resource
    @change_set.prepopulate!
    @change_set.valid? # Run validations to display errors on first load.
  end

  def update
    @change_set = ChangeSet.for(find_resource(params[:id]))
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
  rescue Valkyrie::Persistence::ObjectNotFoundError => not_found_error
    after_update_error not_found_error
  rescue Valkyrie::Persistence::StaleObjectError
    flash[:alert] = "Sorry, another user or process updated this resource simultaneously.  Please resubmit your changes."
    after_update_failure
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
    @change_set = ChangeSet.for(find_resource(params[:id])).prepopulate!
    authorize! :file_manager, @change_set.resource
    file_set_children = Wayfinder.for(@change_set.resource).members_with_parents.select { |x| x.is_a?(FileSet) }
    @children = file_set_children.map do |x|
      ChangeSet.for(x).prepopulate!
    end.to_a
  end

  def order_manager
    @change_set = ChangeSet.for(find_resource(params[:id])).prepopulate!
    authorize! :order_manager, @change_set.resource
  end

  private

    def contextual_path(obj, change_set)
      ContextualPath.new(child: obj.id, parent_id: change_set.append_id)
    end

    def _prefixes
      @_prefixes ||= super + ["base"]
    end

    def resource_params
      h = params[resource_class.to_s.underscore.tr("/", "_").to_sym]&.to_unsafe_h&.deep_symbolize_keys
      clean_params(h)
    end

    def clean_params(h)
      return {} unless h
      h.map do |k, v|
        v.respond_to?(:strip) ? [k, v.strip] : [k, v]
      end.to_h
    end

    def find_resource(id)
      query_service.find_by(id: Valkyrie::ID.new(id))
    end

    def change_set_param
      params[:change_set] || (resource_params && resource_params[:change_set])
    end
end
