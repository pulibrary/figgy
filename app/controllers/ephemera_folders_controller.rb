# frozen_string_literal: true
class EphemeraFoldersController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = EphemeraFolder
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
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
    redirect_to solr_document_path(id: @cached_box.id)
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

  def parent_resource
    find_resource(params[:parent_id])
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
end
