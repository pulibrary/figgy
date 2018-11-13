# frozen_string_literal: true
class NumismaticCitationsController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticCitation
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_numismatic_references, only: [:new, :edit]

  def create
    # Save append_id and then remove from resource params. The new citation id is added to
    # to the parent numismatic_citation_ids property in the add_citation_to_parent method below.
    # The append_id param is then removed so the citation won't be added as a member of the parent.
    @parent_id = resource_params&.[](:append_id)
    params[resource_class.to_s.underscore.to_sym].delete(:append_id) if @parent_id
    super
  end

  def after_create_success(obj, change_set)
    if parent_resource
      add_citation_to_parent(obj)
      obj = parent_resource
    end

    super
  end

  private

    def add_citation_to_parent(obj)
      parent_change_set = DynamicChangeSet.new(parent_resource).prepopulate!
      return unless parent_change_set.respond_to?(:numismatic_citation_ids)
      citations = (parent_resource.numismatic_citation_ids || []) + [obj.id]
      parent_change_set.validate(numismatic_citation_ids: citations)
      change_set_persister.buffer_into_index do |persist|
        persist.save(change_set: parent_change_set)
      end
    end

    def load_numismatic_references
      @numismatic_references = query_service.find_all_of_model(model: NumismaticReference).map(&:decorate).sort_by(&:short_title)
    end

    def parent_resource
      @parent_resource ||= find_resource(@parent_id)
    end
end
