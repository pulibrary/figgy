# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  # Add a filter query to restrict the search to documents the current user has access to
  include Hydra::AccessControlsEnforcement

  def add_access_controls_to_solr_params(*args)
    return if current_ability.can?(:manage, Valkyrie::Resource)
    apply_gated_discovery(*args)
  end
end
