# frozen_string_literal: true
class CatalogController < ApplicationController
  include ::Hydra::Catalog
  include TokenAuth
  layout "application"

  def self.search_config
    {
      "qf" => %w[identifier_tesim
                 figgy_title_ssim
                 figgy_title_tesim
                 transliterated_title_ssim
                 transliterated_title_tesim
                 source_metadata_identifier_ssim
                 local_identifier_ssim
                 barcode_ssim
                 call_number_tsim
                 no_case],
      "qt" => "search",
      "rows" => 10
    }
  end

  # turn off search history during read-only mode
  def find_or_initialize_search_session_from_params(params)
    return if Figgy.read_only_mode
    super
  end

  # enforce hydra access controls
  before_action :set_id, only: :iiif_search
  before_action :enforce_show_permissions, only: [:show, :iiif_search]

  # CatalogController-scope behavior and configuration for BlacklightIiifSearch
  include BlacklightIiifSearch::Controller

  def set_id
    params["id"] = params["solr_document_id"]
  end

  def iiif_search
    _, @document = fetch(params[:solr_document_id])
    authorize! :iiif_search, resource
    super
  end

  configure_blacklight do |config|
    # configuration for Blacklight IIIF Content Search
    config.iiif_search = {
      full_text_field: "ocr_content_tsim",
      object_relation_field: "is_page_of_s",
      supported_params: %w[q page],
      autocomplete_handler: "iiif_suggest",
      suggester_name: "iiifSuggester"
    }

    config.default_solr_params = {
      qf: search_config["qf"],
      qt: search_config["qt"],
      rows: search_config["rows"]
    }

    config.default_per_page = 20

    config.index.title_field = "figgy_title_ssim"
    config.index.display_type_field = "human_readable_type_ssim"
    config.add_facet_field "member_of_collection_titles_ssim", label: "Collections", limit: 5
    config.add_facet_field "human_readable_type_ssim", label: "Type of Work", limit: 5
    config.add_facet_field "ephemera_project_ssim", label: "Ephemera Project", limit: 5
    config.add_facet_field "display_subject_ssim", label: "Subject", limit: 5
    config.add_facet_field "display_language_ssim", label: "Language", limit: 5
    config.add_facet_field "state_ssim", label: "State", limit: 5
    config.add_facet_field "rights_ssim", label: "Rights", limit: 5
    config.add_facet_field "part_of_ssim", label: "Part of", limit: 5
    config.add_facet_field "has_structure_bsi", label: "Has Structure", helper_method: :display_boolean
    config.add_facet_field "depositor_ssim", label: "Depositor"
    config.add_facet_fields_to_solr_request!

    config.add_search_field "all_fields", label: "All Fields"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = "suggest"
    config.show.document_actions.clear
    config.add_show_tools_partial(:admin_controls, partial: "admin_controls", if: :can_edit?)
    config.show.partials = config.show.partials.insert(1, :parent_breadcrumb)
    config.show.partials = config.show.partials.insert(1, :in_process_notification)
    config.show.partials += [:universal_viewer]
    config.show.partials += [:resource_attributes]
    config.show.partials += [:auth_link]
    config.show.partials += [:workflow_controls]
    config.show.partials += [:playlists]
    config.show.partials += [:vocabulary_nav]
    config.show.partials += [:members]
    config.show.partials += [:categories]
    config.show.partials += [:terms]
    config.index.thumbnail_method = :figgy_thumbnail_path
    config.show.document_presenter_class = ValkyrieShowPresenter
    config.index.document_presenter_class = FiggyIndexPresenter

    # "sort results by" options
    config.add_sort_field "score desc, updated_at_dtsi desc", label: "relevance \u25BC"
    config.add_sort_field "title_ssort asc", label: "title (A-Z)"
    config.add_sort_field "title_ssort desc", label: "title (Z-A)"
    config.add_sort_field "created_at_dtsi desc", label: "date created \u25BC"
    config.add_sort_field "created_at_dtsi asc", label: "date created \u25B2"
    config.add_sort_field "updated_at_dtsi desc", label: "date modified \u25BC"
    config.add_sort_field "updated_at_dtsi asc", label: "date modified \u25B2"

    # index fields
    config.add_index_field "source_metadata_identifier_ssim", label: "Source Metadata Identifier"
    config.add_index_field "identifier_ssim", label: "Identifier"
    config.add_index_field "state_ssim", label: "State"
    config.add_index_field "call_number_tsim", label: "Call Number"
    config.add_index_field "part_of_ssim", label: "Part Of"
  end

  # Determine whether or not a user can edit the resource in the current context
  # @return [TrueClass, FalseClass]
  def can_edit?
    return false unless @document
    can?(:edit, @document.resource)
  end

  def has_search_parameters?
    !params[:q].nil? || !params[:f].blank? || !params[:search_field].blank?
  end

  def resource
    @resource ||= @document.resource
  end

  def show
    super
    authorize! :show, resource

    set_parent_document
    @change_set = DynamicChangeSet.new(resource)
    @change_set.prepopulate!
  end

  def set_parent_document
    if params[:parent_id]
      _, @parent_document = fetch(params[:parent_id])
    # we know in our data a fileset never has more than one parent; grab it for breadcrumb convenience
    elsif @document[:internal_resource_ssim].include? "FileSet"
      query = "member_ids_ssim:id-#{params['id']}"
      _, result = search_results(q: query, rows: 1)
      @parent_document = result.first if result.first
    elsif params[:parent_id].nil? && @document.decorated_resource.try(:decorated_parent)
      set_coin_parent
    end
  end

  def set_coin_parent
    params[:parent_id] = @document.decorated_resource.decorated_parent["id"].to_s
    _, @parent_document = fetch(params[:parent_id])
  end

  def lookup_manifest
    ark = "#{params[:prefix]}/#{params[:naan]}/#{params[:arkid]}"
    query = "identifier_ssim:#{RSolr.solr_escape(ark)}"
    _, result = search_results(q: query, fl: "id, internal_resource_ssim", rows: 1)

    if result.first
      object_id = result.first["id"]
      model_name = result.first["internal_resource_ssim"].first.underscore.to_sym
      url = polymorphic_url([:manifest, model_name], id: object_id)
      params[:no_redirect] ? render(json: { url: url }) : redirect_to(url)
    else
      render json: { message: "No manifest found for #{ark}" }, status: 404
    end
  end
end
