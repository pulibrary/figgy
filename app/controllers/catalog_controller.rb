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

  configure_blacklight do |config|
    config.default_solr_params = {
      qf: search_config['qf'],
      qt: search_config['qt'],
      rows: search_config['rows']
    }

    config.index.title_field = 'title_ssim'
    config.index.display_type_field = "internal_resource_ssim"
    config.add_facet_field 'title_ssim', label: 'Title'
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
    config.show.partials += [:resource_attributes]
  end

  def admin?
    can?(:manage, @document.resource)
  end

  def has_search_parameters?
    !params[:q].nil? || !params[:f].blank? || !params[:search_field].blank?
  end
end
