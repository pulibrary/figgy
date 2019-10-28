# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  # Add a filter query to restrict the search to documents the current user has access to
  include Hydra::AccessControlsEnforcement
  delegate :unreadable_states, to: :current_ability
  self.default_processor_chain += [:filter_models, :filter_parented, :hide_incomplete]
  attr_writer :relation

  def relation
    @relation ||= query_service.resources # .where(Sequel.pg_jsonb_op(:metadata).contains(state: ["complete"], read_groups: ["public"]))
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end

  # Add queries that excludes everything except for works and collections
  def filter_models(solr_parameters)
    self.relation = relation.exclude(Sequel[:orm_resources][:internal_resource] => models_to_solr_clause.split(","))
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "!{!terms f=internal_resource_ssim}#{models_to_solr_clause}"
  end

  # Keeps child resources of multi-volume works (MVWs) from appearing in results
  def filter_parented(solr_params)
    self.relation = relation.select_all(:orm_resources).left_join(Sequel[:orm_resources].as(:b)) { |j, lj, js| Sequel.function(:"public.get_ids", Sequel[j][:metadata].pg_jsonb, 'member_ids').pg_jsonb.has_key?((Sequel[lj][:id].cast(:text)))}.where(Sequel[:b][:id] => nil)
    solr_params[:fq] ||= []
    solr_params[:fq] << "!member_of_ssim:['' TO *]"
  end

  def hide_incomplete(solr_params)
    # admin route causes errors with current_ability.
    return if blacklight_params.empty?
    return if unreadable_states.blank?
    statements = readable_states.map do |state|
      Sequel[:orm_resources][:metadata].pg_jsonb.contains(state: [state])
    end
    statements += [{ Sequel[:orm_resources][:internal_resource] => "Collection" }]
    self.relation = relation.where(Sequel.|(*statements))
    solr_params[:fq] ||= []
    state_string = readable_states.map { |state| "state_ssim:#{state}" }.join(" OR ")
    state_string += " OR " unless state_string == ""
    state_string += "has_model_ssim:Collection"
    solr_params[:fq] << state_string
  end

  def readable_states
    WorkflowRegistry.all_states - unreadable_states
  end

  # This is a blacklist of models that should not be presented in search results
  def models_to_solr_clause
    [
      FileMetadata,
      FileSet,
      EphemeraField,
      EphemeraProject,
      EphemeraTerm,
      EphemeraVocabulary,
      Numismatics::Accession,
      Numismatics::Citation,
      Numismatics::Artist,
      Numismatics::Firm,
      Numismatics::Loan,
      Numismatics::Monogram,
      Numismatics::Place,
      Numismatics::Person,
      Numismatics::Provenance,
      Numismatics::Reference,
      ProxyFileSet,
      Template,
      PreservationObject,
      Tombstone
    ].join(",")
  end

  def add_access_controls_to_solr_params(*args)
    return if current_ability.can?(:manage, Valkyrie::Resource)
    apply_gated_discovery(*args)
  end
end
