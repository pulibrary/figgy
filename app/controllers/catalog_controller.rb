# frozen_string_literal: true
class CatalogController < ApplicationController
  include ::Hydra::Catalog
  include TokenAuth
  layout "application"
  def self.search_config
    {
      "qf" => %w[identifier_tesim title_ssim title_tesim transliterated_title_ssim transliterated_title_tesim source_metadata_identifier_ssim local_identifier_ssim barcode_ssim],
      "qt" => "search",
      "rows" => 10
    }
  end

  # The search builder to find the collections' members
  class_attribute :member_search_builder_class
  self.member_search_builder_class = CollectionMemberSearchBuilder

  # enforce hydra access controls
  before_action :enforce_show_permissions, only: :show

  configure_blacklight do |config|
    config.default_solr_params = {
      qf: search_config["qf"],
      qt: search_config["qt"],
      rows: search_config["rows"]
    }

    config.index.title_field = "title_ssim"
    config.index.display_type_field = "human_readable_type_ssim"
    config.add_facet_field "member_of_collection_titles_ssim", label: "Collections", limit: 5
    config.add_facet_field "human_readable_type_ssim", label: "Type of Work", limit: 5
    config.add_facet_field "ephemera_project_ssim", label: "Ephemera Project", limit: 5
    config.add_facet_field "display_subject_ssim", label: "Subject", limit: 5
    config.add_facet_field "display_language_ssim", label: "Language", limit: 5
    config.add_facet_field "state_ssim", label: "State", limit: 5
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
    config.show.partials += [:universal_viewer]
    config.show.partials += [:media_html5_player]
    config.show.partials += [:resource_attributes]
    config.show.partials += [:workflow_controls]
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
    @document_facade = document_facade
    @response = @document_facade.query_response unless @document_facade.members.empty?
  end

  def set_parent_document
    if params[:parent_id]
      _, @parent_document = fetch(params[:parent_id])
    # we know in our data a fileset never has more than one parent; grab it for breadcrumb convenience
    elsif @document[:internal_resource_ssim].include? "FileSet"
      query = "member_ids_ssim:id-#{params['id']}"
      _, result = search_results(q: query, rows: 1)
      @parent_document = result.first if result.first
    end
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

  private

    # Instantiates the search builder that builds a query for items that are
    # members of the current collection. This is used in the show view.
    def member_search_builder
      @member_search_builder ||= member_search_builder_class.new(self)
    end

    # You can override this method if you need to provide additional inputs to the search
    # builder. For example:
    #   search_field: 'all_fields'
    # @return <Hash> the inputs required for the collection member search builder
    def params_for_members_query
      params.merge(q: params[:cq])
    end

    # @return <Hash> a representation of the solr query that find the collection members
    def query_for_collection_members
      member_search_builder.with(params_for_members_query).query
    end

    def current_page
      params.fetch(:page, 1)
    end

    def per_page
      params.fetch(:per_page, 10)
    end

    def document_facade
      SolrFacade.new(
        repository: repository,
        query: query_for_collection_members,
        current_page: current_page,
        per_page: per_page
      )
    end
end
