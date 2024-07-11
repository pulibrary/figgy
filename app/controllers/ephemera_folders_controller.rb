# frozen_string_literal: true
class EphemeraFoldersController < ResourcesController
  self.resource_class = EphemeraFolder
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_fields, only: [:new, :edit, :update, :create]
  before_action :cache_parent, only: [:destroy]
  before_action :load_boxes, only: [:edit]
  before_action :skip_validation, only: [:update, :create]

  include Pdfable

  def change_set_param
    parent_resource.is_a?(EphemeraBox) ? "ephemera_folder" : "boxless_ephemera_folder"
  end

  def after_create_success(obj, _change_set)
    if params[:commit] == "Save and Duplicate Metadata"
      redirect_to parent_new_ephemera_box_path(parent_id: resource_params[:append_id], create_another: obj.id.to_s), notice: "Folder #{obj.folder_number.first} Saved, Creating Another..."
    else
      super
    end
  end

  def skip_validation
    return unless params[:commit] == "Save Draft"
    resource_params[:skip_validation] = true
  end

  def after_update_success(obj, _change_set)
    if params[:commit] == "Save and Duplicate Metadata"
      redirect_to parent_new_ephemera_box_path(parent_id: obj.decorate.parent.id, create_another: obj.id.to_s), notice: "Folder #{obj.folder_number.first} Saved, Creating Another..."
    else
      super
    end
  end

  def cache_parent
    @cached_parent = find_resource(params[:id]).decorate.parent
  end

  def after_delete_success
    redirect_to solr_document_path(id: @cached_parent.id)
  end

  def new_resource
    if params[:template_id]
      template = find_resource(params[:template_id])
      template.nested_properties.first
    elsif params[:create_another]
      resource = find_resource(params[:create_another])
      # Setting new_record to true ensures that this is not treated as a persisted Resource
      # @see Valkyrie::Resource#persisted?
      # @see https://github.com/samvera-labs/valkyrie/blob/master/lib/valkyrie/resource.rb#L83
      resource.new(id: nil, new_record: true, created_at: nil, updated_at: nil, barcode: nil, folder_number: nil)
    else
      resource_class.new
    end
  end

  def manifest
    authorize! :manifest, resource
    respond_to do |f|
      f.json do
        render json: cached_manifest(resource, auth_token_param)
      end
    end
  end

  def cached_manifest(resource, auth_token_param)
    Rails.cache.fetch("#{ManifestKey.for(resource)}/#{auth_token_param}") do
      builder_klass = if Wayfinder.for(resource).first_member.try(:av?)
                        ManifestBuilderV3
                      else
                        ManifestBuilder
                      end
      builder_klass.new(resource, auth_token_param).build.to_json
    end
  end

  def auth_token_param
    params[:auth_token]
  end

  # @returns Valkyrie::Resource or nil
  # @note Returns nil if resource has no parent and params[:parent_id] has not been set
  #   This is common in tests but UI doesn't permit it in production
  def parent_resource
    @parent_resource ||=
      if params[:id]
        find_resource(params[:id]).decorate.parent
      elsif params[:parent_id]
        find_resource(params[:parent_id])
      end
  end

  def fields
    @fields ||= ephemera_project.fields
  rescue => e
    Rails.logger.warn e
    []
  end

  # provides instance variables to views
  #   e.g. array of decorated EphemeraTerms at
  #   app/views/records/edit_fields/_language.html.erb
  def load_fields
    @parent_box_number = ephemera_box.box_number.first if ephemera_box
    fields.each do |field|
      instance_variable_set("@#{field.attribute_name}", field.sorted_terms_or_categories)
    end
  end

  # provides instance variables needed to populate collection and selected for append_id
  # @see app/views/ephemera_folders/edit_fields/_append_id.html.erb
  def load_boxes
    @available_boxes = available_boxes
    @selected_box = ephemera_box&.id.to_s
    @add_to_box = true
  end

  # returns decorators
  def available_boxes
    if ephemera_project
      ephemera_project.boxes
    else
      []
    end.unshift(nil_box)
  end

  def ephemera_box
    parent_resource.is_a?(EphemeraBox) ? parent_resource : nil
  end

  def nil_box
    Struct.new(:title, :id).new("", "")
  end

  def top_languages
    ephemera_project.top_language
  end
  helper_method :top_languages

  # returns decorated project
  # or nil if #parent_resource was nil
  def ephemera_project
    return if parent_resource.nil?
    parent_resource.is_a?(EphemeraProject) ? parent_resource.decorate : parent_resource.decorate.ephemera_project
  end
end
