# frozen_string_literal: true
class CatalogController < ApplicationController
  include BlacklightRangeLimit::ControllerOverride
  # @note If you're looking for the JSON-LD generation code, please see the
  #   LinkedData module in `app/models/concerns/linked_data.rb`. It gets
  #   registered here through `SolrDocument.use_extension`.
  include ::Hydra::Catalog
  include TokenAuth
  layout "application"

  before_action :notify_read_only, :notify_index_read_only

  # Overriding to allow access to jsonld:
  # @see upstream https://github.com/projectblacklight/blacklight-access_controls/blob/089cb43377086adba46e4cde272c2ccb19fef5ad/lib/blacklight/access_controls/catalog.rb#L11
  # @see upstream https://github.com/samvera/hydra-head/blob/6fc0e369a3f652cf06656a20354c4c4b972f9b09/hydra-core/app/controllers/concerns/hydra/catalog.rb#L13
  #
  # Just prepare the permissions doc. Everything else done upstream we do in
  # our code, anyway (e.g. read, embargo permissions).
  def enforce_show_permissions(_opts = {})
    current_ability.permissions_doc(params[:id])
  end

  def notify_index_read_only
    return unless Figgy.index_read_only?
    message = ["Figgy is currently undergoing maintenance and resource ingest and editing is disabled."]
    message << flash[:notice] if flash[:notice] && flash[:notice] != message.first
    flash[:notice] = message.join(" ")
  end

  def notify_read_only
    return unless Figgy.read_only_mode
    message = ["The site is currently in read-only mode."]
    message << flash[:notice] if flash[:notice] && flash[:notice] != message.first
    flash[:notice] = message.join(" ")
  end

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
  before_action :set_id, only: [:iiif_search, :pdf]
  before_action :enforce_show_permissions, only: [:show, :iiif_search]
  before_action :claimed_by_facet

  # CatalogController-scope behavior and configuration for BlacklightIiifSearch
  include BlacklightIiifSearch::Controller

  def set_id
    params["id"] = params["solr_document_id"]
  end

  def claimed_by_facet
    return unless current_user && (current_user.staff? || current_user.admin?)
    return if blacklight_config.facet_fields.key?("claimed_by_ssim")
    blacklight_config.add_facet_field "claimed_by_ssim", query: {
      unclaimed: { label: "Unclaimed", fq: "-claimed_by_ssim:[* TO *]" },
      claimed: { label: "Claimed", fq: "claimed_by_ssim:[* TO *]" },
      claimed_by_me: { label: "Claimed by Me", fq: "claimed_by_ssim:#{current_user.uid}" }
    }, label: "Claimed"
  end

  def iiif_search
    _, @document = search_service.fetch(params[:solr_document_id])
    authorize! :iiif_search, resource
    super
  end

  configure_blacklight do |config|
    # Ensures that JSON representations of resources can be retrieved using
    # the path /catalog/:id/raw
    config.raw_endpoint.enabled = true

    # Turn off search session tracking
    # Interferes with thumbnail display in FileSet manager
    config.track_search_session = false

    # Add extra permitted params
    # https://github.com/projectblacklight/blacklight/blob/v7.28.0/lib/blacklight/parameters.rb#L84-L89
    # pul_controller_params aren't used by the search state. We're adding them
    # to this config to quiet deprecation warnings but we should try removing
    # them when upgrading to blacklight 8, as we suspect it's fine to have them
    # stripped out for search.
    pul_controller_params = [
      :arkid,
      :all_models,
      :append_collection_ids,
      :auth_token,
      :batch_size,
      :change_set,
      :commit,
      :create_another,
      :ephemera_project_id,
      :formats,
      :mark_complete,
      :model_class,
      :naan,
      :no_redirect,
      :ocr_language,
      :parent_id,
      :prefix,
      :remove_collection_ids,
      :rights_statement,
      :save_and_ingest_path,
      :scanned_resource,
      :search_params,
      :solr_document_id,
      :template_id,
      :utf8,
      :visibility
    ]
    config.search_state_fields = config.search_state_fields + [:id] + pul_controller_params

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
    config.show.display_type_field = "human_readable_type_ssim"
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
    config.add_facet_field "visibility_ssim", label: "Visibility", helper_method: :render_visibility_label
    config.add_facet_field "pub_date_start_itsi", label: "Date", single: true, range: {
      num_segments: 10,
      assumed_boundaries: [1100, Time.current.year + 1],
      segments: true
    }
    config.add_facet_fields_to_solr_request!

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)
    config.add_results_collection_tool(:bulk_edit_button)
    config.add_results_document_tool(:bookmark, partial: "bookmark_control", if: :render_bookmarks_control?)
    config.add_nav_action(:bookmark, partial: "blacklight/nav/bookmark", if: :render_bookmarks_control?)

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

    # Configuration to correctly render show page title element
    config.show.html_title_field = "figgy_title_ssim"

    # "sort results by" options
    config.add_sort_field "score desc, updated_at_dtsi desc", label: "relevance \u25BC"
    config.add_sort_field "title_ssort asc", label: "title (A-Z)"
    config.add_sort_field "title_ssort desc", label: "title (Z-A)"
    config.add_sort_field "created_at_dtsi desc", label: "date created \u25BC"
    config.add_sort_field "created_at_dtsi asc", label: "date created \u25B2"
    config.add_sort_field "updated_at_dtsi desc", label: "date modified \u25BC"
    config.add_sort_field "updated_at_dtsi asc", label: "date modified \u25B2"

    # index fields
    config.add_index_field "imported_creator_tesim", label: "Creator"
    config.add_index_field "source_metadata_identifier_ssim", label: "Source Metadata Identifier"
    config.add_index_field "identifier_ssim", label: "Identifier"
    config.add_index_field "state_ssim", label: "State"
    config.add_index_field "call_number_tsim", label: "Call Number"
    config.add_index_field "part_of_ssim", label: "Part Of"
    config.add_index_field "imported_date_created_tesim", label: "Date"
    config.add_index_field "figgy_title_ssi"
  end

  # Determine whether or not a user can edit the resource in the current context
  # @return [TrueClass, FalseClass]
  def can_edit?
    return false unless @document
    can?(:edit, @document.resource)
  end

  def has_search_parameters?
    !params[:q].nil? || params[:f].present? || params[:search_field].present?
  end

  def resource
    @resource ||= @document.resource
  end

  def show
    super
    authorize! :show, resource

    set_parent_document
    @change_set = ChangeSet.for(resource)
    @change_set.prepopulate!
  end

  def set_parent_document
    if params[:parent_id]
      _, @parent_document = search_service.fetch(params[:parent_id])
    # we know in our data a fileset never has more than one parent; grab it for breadcrumb convenience
    elsif @document[:internal_resource_ssim].include? "FileSet"
      query = "member_ids_ssim:id-#{params['id']}"
      _, result = search_service.search_results do |search_builder|
        search_builder.with(q: query, rows: 1)
      end
      @parent_document = result.first if result.first
    elsif params[:parent_id].nil? && @document.decorated_resource.try(:decorated_parent)
      set_coin_parent
    end
  end

  def set_coin_parent
    params[:parent_id] = @document.decorated_resource.decorated_parent["id"].to_s
    _, @parent_document = search_service.fetch(params[:parent_id])
  end

  def lookup_manifest
    ark = "#{params[:prefix]}/#{params[:naan]}/#{params[:arkid]}"
    query = "identifier_ssim:#{RSolr.solr_escape(ark)}"
    _, result = search_service.search_results do |search_builder|
      search_builder.with(q: query, fl: "id, internal_resource_ssim", rows: 1)
    end

    if result.first
      object_id = result.first["id"]
      model_name = result.first["internal_resource_ssim"].first.underscore.to_sym
      url = polymorphic_url([:manifest, model_name], id: object_id)
      params[:no_redirect] ? render(json: { url: url }) : redirect_to(url)
    else
      render json: { message: "No manifest found for #{ark}" }, status: :not_found
    end
  end

  # This endpoint redirects to download an original pdf if present,
  # or redirects to the resource pdf endpoint if one needs to be generated
  def pdf
    _, @document = search_service.fetch(params[:solr_document_id])

    source_pdf = Wayfinder.for(resource).source_pdf
    if source_pdf
      redirect_to "#{request.base_url}#{helpers.fileset_download_path(source_pdf, auth_token_param)}"
    elsif helpers.pdf_allowed?(resource) && can?(:pdf, resource)
      redirect_to "#{request.base_url}#{polymorphic_path([:pdf, resource], auth_token_param)}"
    else
      redirect_to solr_document_url(resource), notice: "No PDF available for this item"
    end
  end

  private

    def auth_token_param
      return {} unless params[:auth_token]
      { auth_token: params[:auth_token] }
    end
end
