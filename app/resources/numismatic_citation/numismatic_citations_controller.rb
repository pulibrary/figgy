# frozen_string_literal: true
class NumismaticCitationsController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticCitation
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_numismatic_references, only: [:new, :edit]

  def new
    @change_set = change_set_class.new(new_resource, citation_parent_id: params[:parent_id]).prepopulate!
    authorize! :create, resource_class
  end

  def after_create_success(obj, change_set)
    # Redirect to parent resource
    obj = parent_resource if parent_resource
    super
  end

  private

    def load_numismatic_references
      @numismatic_references = query_service.find_all_of_model(model: NumismaticReference).map(&:decorate).sort_by(&:short_title)
    end

    def parent_resource
      @parent_resource ||= find_resource(@change_set.citation_parent_id)
    end
end
