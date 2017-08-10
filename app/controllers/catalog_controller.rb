# frozen_string_literal: true
class CatalogController < ApplicationController
  include ::Hydra::Catalog
  layout "application"
  def self.search_config
    {
      'qf' => %w[title_ssim],
      'qt' => 'search',
      'rows' => 10
    }
  end
  before_action :parent_document, only: :show

  configure_blacklight do |config|
    config.default_solr_params = {
      qf: search_config['qf'],
      qt: search_config['qt'],
      rows: search_config['rows']
    }

    config.index.title_field = 'title_ssim'
    config.index.display_type_field = "internal_resource_ssim"
    config.add_facet_field 'member_of_collection_titles_ssim', label: 'Collections'
    config.add_facet_field 'internal_resource_ssim', label: 'Type of Work'
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
    config.index.thumbnail_method = :figgy_thumbnail_path
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
    _, @parent_document = fetch("id-#{params[:parent_id]}")
  end

  def lookup_manifest
    ark = "#{params[:prefix]}/#{params[:naan]}/#{params[:arkid]}"
    query = "identifier_ssim:#{RSolr.solr_escape(ark)}"
    _, result = search_results(q: query, fl: "id, internal_resource_ssim", rows: 1)

    if result.first
      object_id = result.first['id'].gsub(/^id-/, '')
      model_name = result.first['internal_resource_ssim'].first.underscore.to_sym
      url = polymorphic_url([:manifest, model_name], id: object_id)
      params[:no_redirect] ? render(json: { url: url }) : redirect_to(url)
    else
      render json: { message: "No manifest found for #{ark}" }, status: 404
    end
  end
end
