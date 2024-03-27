# frozen_string_literal: true

# A base controller for resources, intended for inheritance
class ResourcesController < ApplicationController
  class_attribute :resource_class, :change_set_persister
  include TokenAuth
  include Blacklight::SearchContext
  before_action :load_collections, only: [:new, :edit, :update, :create]
  delegate :metadata_adapter, to: :change_set_persister
  delegate :persister, :query_service, to: :metadata_adapter
  skip_before_action :verify_authenticity_token, only: [:refresh_remote_metadata]

  def refresh_remote_metadata
    authorize! :refresh_remote_metadata, :json_document
    body = JSON.parse(request.body.read)
    codes = body["archival_collection_codes"]
    return if codes.blank?
    codes.each do |code|
      RefreshArchivalCollectionJob.perform_later(collection_code: code)
    end

    head :accepted
  end

  def new
    @change_set = ChangeSet.for(new_resource, append_id: params[:parent_id], change_set_param: change_set_param).prepopulate!
    authorize_create!(change_set: @change_set)
  rescue ChangeSet::NotFoundError
    Valkyrie.logger.error("Failed to find the ChangeSet class for #{change_set_param}.")
    flash[:error] = "#{change_set_param} is not a valid resource type."
    redirect_to new_scanned_resource_path
  end

  # For new/create if a resource is going to be appended to a parent, the
  # permissions should be based on the ability to update the parent it's going
  # to be appended to. Enables users who only have permission to add to a single
  # Ephemera Project.
  def authorize_create!(change_set:)
    if change_set.append_id.present?
      authorize! :update, query_service.find_by(id: Array(change_set.append_id).first)
    else
      authorize! :create, resource_class
    end
  end

  def new_resource
    resource_class.new
  end

  def create
    @change_set = ChangeSet.for(resource_class.new, change_set_param: change_set_param)
    @change_set.validate(resource_params.merge(depositor: [current_user&.uid]))
    authorize_create!(change_set: @change_set)
    if @change_set.valid?
      obj = nil
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        obj = buffered_changeset_persister.save(change_set: @change_set)
      end
      after_create_success(obj, @change_set)
    else
      Valkyrie.logger.warn(@change_set.errors.details.to_s)
      render :new
    end
  rescue SourceMetadataIdentifierValidator::InvalidMetadataIdentifierError => invalid_metadata_id_error
    Valkyrie.logger.error(invalid_metadata_id_error.message)
    flash[:error] = invalid_metadata_id_error.message
    render :new
  end

  def after_create_success(obj, _change_set)
    redirect_to solr_document_path(obj)
  end

  def destroy
    @change_set = ChangeSet.for(find_resource(params[:id]))
    authorize! :destroy, @change_set.resource
    around_delete_action do
      change_set_persister.buffer_into_index do |persist|
        persist.delete(change_set: @change_set)
      end
      flash[:alert] = "Deleted #{@change_set.resource}"
      after_delete_success
    end
  end

  # Overridable method to enable controlling delete behavior in inherited
  # controllers. @change_set is accessible here.
  def around_delete_action
    yield
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
        flash[:confetti] = true if @change_set.try(:state_changed?) && @change_set.new_state == "complete"
      end
      after_update_success(obj, @change_set)
    else
      after_update_failure
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError => not_found_error
    after_update_error not_found_error
  rescue Valkyrie::Persistence::StaleObjectError
    flash[:alert] = "Sorry, another user or process updated this resource simultaneously. Please resubmit your changes."
    after_update_failure
  end

  def after_update_success(obj, _change_set)
    respond_to do |format|
      format.html do
        redirect_to solr_document_path(obj)
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

  def load_collections
    @collections = query_service.find_all_of_model(model: Collection).map(&:decorate) || []
  end

  def resource
    find_resource(params[:id])
  end

  def change_set
    @change_set ||= ChangeSet.for(resource)
  end

  # Used for submissions from the FileBrowser in the File Manager interface.
  def server_upload
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      change_set.validate(pending_uploads: change_set.pending_uploads + new_pending_uploads)
      buffered_changeset_persister.save(change_set: change_set)
    end
    ServerUploadJob.perform_later(change_set.id.to_s, new_pending_uploads.map(&:id).map(&:to_s))

    redirect_to polymorphic_path([:file_manager, resource])
  end

  # Remove the resource from given parent
  def remove_from_parent
    @change_set = ChangeSet.for(resource)
    parent_resource = find_resource(parent_resource_params[:id])
    authorize! :update, parent_resource

    parent_change_set = ChangeSet.for(parent_resource)
    current_member_ids = parent_resource.member_ids
    parent_change_set.member_ids = current_member_ids - [resource.id]

    obj = nil
    change_set_persister.buffer_into_index do |persist|
      obj = persist.save(change_set: parent_change_set)
    end
    after_update_success(obj, @change_set)
  rescue Valkyrie::Persistence::ObjectNotFoundError => e
    after_update_error e
  end

  private

    def _prefixes
      @_prefixes ||= super + ["base"]
    end

    def resource_params
      @resource_params ||=
        begin
          h = params[resource_class.to_s.underscore.tr("/", "_").to_sym]&.to_unsafe_h&.deep_symbolize_keys
          clean_params(h)
        end
    end

    def clean_params(h)
      return {} unless h
      h.map do |k, v|
        # The vue widget uploads files named scanned_resource[files][0] instead
        # of scanned_resource[files][], this converts the resulting hash back to
        # an array.
        if k.to_s == "files" && v.is_a?(Hash)
          [k, v.values]
        else
          v.respond_to?(:strip) ? [k, v.strip] : [k, v]
        end
      end.to_h
    end

    def find_resource(id)
      query_service.find_by(id: Valkyrie::ID.new(id))
    end

    def change_set_param
      params[:change_set] || (resource_params && resource_params[:change_set])
    end

    def parent_resource_params
      params[:parent_resource].to_unsafe_h
    end

    # Construct the pending download objects
    # @return [Array<PendingUpload>]
    def new_pending_uploads
      @new_pending_uploads ||=
        begin
          metadata_ingest_files ||
            (params[:ingest_files] || []).map do |ingest_file|
              # Skip hidden files.
              next if ingest_file.split("/").last.start_with?(".")
              file = Valkyrie::StorageAdapter.find_by(id: ingest_file)
              PendingUpload.new(
                id: SecureRandom.uuid,
                storage_adapter_id: file.id,
                created_at: Time.current,
                file_name: ingest_file.split("/").last
              )
            rescue
              nil
            end.compact
        end.flatten
    end

    # Local file ingest submits file metadata as JSON in fields.
    def metadata_ingest_files
      return if params[:metadata_ingest_files].blank?
      params[:metadata_ingest_files].map do |metadata|
        metadata = JSON.parse(metadata, symbolize_names: true)
        file = Valkyrie::StorageAdapter.find_by(id: metadata[:id])
        PendingUpload.new(
          id: SecureRandom.uuid,
          storage_adapter_id: file.id,
          created_at: Time.current,
          file_name: metadata[:filename],
          type: metadata[:type]
        )
      rescue
        nil
      end.compact
    end
end
