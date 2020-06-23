# frozen_string_literal: true
class TemplatesController < ApplicationController
  include ResourceController
  self.resource_class = Template
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  before_action :find_parent, only: [:new, :create, :destroy]
  before_action :load_fields, only: [:new]
  before_action :load_collections, only: [:new, :edit, :update, :create]

  def find_parent
    @parent ||= query_service.find_by(id: Valkyrie::ID.new(params[:ephemera_project_id]))
  end

  def new
    @parent_change_set = TemplateChangeSet.new(Template.new(model_class: params[:model_class]))
    @parent_change_set.prepopulate!
    @change_set = @parent_change_set.child_change_set
  end

  def after_create_success(_obj, _change_set)
    redirect_to solr_document_path(id: @parent.id)
  end

  def after_delete_success
    after_create_success(nil, nil)
  end

  def resource_params
    params[:template].merge(parent_id: @parent.id.to_s)
  end

  def _prefixes
    @_prefixes ||= super + ["base"]
  end

  def load_collections
    @collections = query_service.find_all_of_model(model: Collection).map(&:decorate) || []
  end

  def load_fields
    fields.each do |field|
      case field.attribute_name
      when "subject"
        @subject = field.vocabulary.categories
      else
        instance_variable_set("@#{field.attribute_name}", field.vocabulary.terms)
      end
    end
  end

  def fields
    @fields ||= find_parent.decorate.fields
  end

  def top_languages
    # parent is always an ephemera project
    find_parent.decorate.top_language
  end
  helper_method :top_languages
end
