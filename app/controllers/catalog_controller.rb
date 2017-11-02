# frozen_string_literal: true
class CatalogController < ApplicationController
  include ::Hydra::Catalog
  layout "application"
  def self.search_config
    {
      'qf' => %w[identifier_tesim title_ssim title_tesim source_metadata_identifier_ssim local_identifier_ssim barcode_ssim],
      'qt' => 'search',
      'rows' => 10
    }
  end
  before_action :parent_document, only: :show

  # enforce hydra access controls
  before_action :enforce_show_permissions, only: :show

  configure_blacklight do |config|
    config.default_solr_params = {
      qf: search_config['qf'],
      qt: search_config['qt'],
      rows: search_config['rows']
    }

    config.index.title_field = 'title_ssim'
    config.index.display_type_field = "human_readable_type_ssim"
    config.add_facet_field 'member_of_collection_titles_ssim', label: 'Collections'
    config.add_facet_field 'human_readable_type_ssim', label: 'Type of Work'
    config.add_facet_field 'ephemera_project_ssim', label: 'Ephemera Project'
    config.add_facet_field 'display_subject_ssim', label: 'Subject'
    config.add_facet_field 'display_language_ssim', label: 'Language'
    config.add_facet_field 'state_ssim', label: 'State'
    config.add_facet_fields_to_solr_request!

    config.add_search_field 'all_fields', label: 'All Fields'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'
    config.show.document_actions.clear
    config.add_show_tools_partial(:admin_controls, partial: 'admin_controls', if: :admin?)
    config.show.partials = config.show.partials.insert(1, :parent_breadcrumb)
    config.show.partials += [:universal_viewer]
    config.show.partials += [:resource_attributes]
    config.show.partials += [:workflow_controls]
    config.show.partials += [:vocabulary_nav]
    config.show.partials += [:members]
    config.show.partials += [:categories]
    config.show.partials += [:terms]
    config.index.thumbnail_method = :figgy_thumbnail_path
    config.show.document_presenter_class = ValkyrieShowPresenter

    # "sort results by" options
    config.add_sort_field "score desc, updated_at_dtsi desc", label: "relevance \u25BC"
    config.add_sort_field "title_ssort asc", label: "title (A-Z)"
    config.add_sort_field "title_ssort desc", label: "title (Z-A)"
    config.add_sort_field "created_at_dtsi desc", label: "date created \u25BC"
    config.add_sort_field "created_at_dtsi asc", label: "date created \u25B2"
    config.add_sort_field "updated_at_dtsi desc", label: "date modified \u25BC"
    config.add_sort_field "updated_at_dtsi asc", label: "date modified \u25B2"
  end

  def admin?
    can?(:manage, @document.resource)
  end

  def has_search_parameters?
    !params[:q].nil? || !params[:f].blank? || !params[:search_field].blank?
  end

  def show
    super
    @change_set = DynamicChangeSet.new(@document.resource)
    @change_set.prepopulate!
  end

  def parent_document
    return unless params[:parent_id]
    _, @parent_document = fetch(params[:parent_id])
  end

  def lookup_manifest
    ark = "#{params[:prefix]}/#{params[:naan]}/#{params[:arkid]}"
    query = "identifier_ssim:#{RSolr.solr_escape(ark)}"
    _, result = search_results(q: query, fl: "id, internal_resource_ssim", rows: 1)

    if result.first
      object_id = result.first['id']
      model_name = result.first['internal_resource_ssim'].first.underscore.to_sym
      url = polymorphic_url([:manifest, model_name], id: object_id)
      params[:no_redirect] ? render(json: { url: url }) : redirect_to(url)
    else
      render json: { message: "No manifest found for #{ark}" }, status: 404
    end
  end
end
