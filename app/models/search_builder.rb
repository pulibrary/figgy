# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  # Add a filter query to restrict the search to documents the current user has access to
  include Hydra::AccessControlsEnforcement
  self.default_processor_chain += [:filter_models]

  # Add queries that excludes everything except for works and collections
  def filter_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!terms f=internal_resource_ssim}#{models_to_solr_clause}"
  end

  def models_to_solr_clause
    [ScannedResource, Collection].join(",")
  end

  def add_access_controls_to_solr_params(*args)
    return if current_ability.can?(:manage, Valkyrie::Resource)
    apply_gated_discovery(*args)
  end
end
