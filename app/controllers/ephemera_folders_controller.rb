# frozen_string_literal: true
class EphemeraFoldersController < ApplicationController
  include Valhalla::ResourceController
  include TokenAuth
  self.change_set_class = DynamicChangeSet
  self.resource_class = EphemeraFolder
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_collections, only: [:new, :edit]
  before_action :load_fields, only: [:new, :edit]
  before_action :cache_box, only: [:destroy]

  def after_create_success(obj, _change_set)
    if params[:commit] == "Save and Create Another"
      redirect_to parent_new_ephemera_box_path(parent_id: resource_params[:append_id], create_another: obj.id.to_s)
    else
      super
    end
  end

  def cache_box
    @cached_box = find_resource(params[:id]).decorate.ephemera_box
  end

  def after_delete_success
    redirect_to solr_document_path(id: "id-#{@cached_box.id}")
  end

  def new_resource
    if params[:template_id]
      template = find_resource(params[:template_id])
      template.nested_properties.first
    elsif params[:create_another]
      resource = find_resource(params[:create_another])
      resource.new(id: nil, created_at: nil, updated_at: nil)
    else
      resource_class.new
    end
  end

  def manifest
    authorize! :manifest, resource
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(resource).build
      end
    end
  end

  def selected_file_params
    params[:selected_files].to_unsafe_h
  end

  def selected_files
    @selected_files ||= selected_file_params.values.map do |x|
      PendingUpload.new(x.symbolize_keys.merge(id: SecureRandom.uuid, created_at: Time.current.utc.iso8601))
    end
  end

  def resource
    find_resource(params[:id])
  end

  def parent_resource
    find_resource(params[:parent_id])
  end

  def change_set
    @change_set ||= change_set_class.new(resource)
  end

  def load_collections
    @collections = query_service.find_all_of_model(model: Collection).map(&:decorate)
  end

  def ephemera_box
    @ephemera_box ||= params[:parent_id] ? parent_resource.decorate : resource.decorate.ephemera_box
  rescue => e
    Rails.logger.warn e
    nil
  end

  def fields
    @fields ||= ephemera_box.ephemera_project.fields
  rescue => e
    Rails.logger.warn e
    []
  end

  def load_fields
    fields.each do |field|
      case field.attribute_name
      when 'subject'
        @subject = field.vocabulary.categories
      else
        instance_variable_set("@#{field.attribute_name}", field.vocabulary.terms)
      end
    end
  end

  def browse_everything_files
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      change_set.validate(pending_uploads: change_set.pending_uploads + selected_files)
      change_set.sync
      buffered_changeset_persister.save(change_set: change_set)
    end
    BrowseEverythingIngestJob.perform_later(resource.id.to_s, self.class.to_s, selected_files.map(&:id).map(&:to_s))
    redirect_to Valhalla::ContextualPath.new(child: resource, parent_id: nil).file_manager
  end
end
