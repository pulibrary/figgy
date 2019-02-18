# frozen_string_literal: true
class NumismaticIssuesController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticIssue
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  before_action :load_monograms, only: [:new, :edit]

  def load_monograms
    @numismatic_monograms = query_service.find_all_of_model(model: NumismaticMonogram).map(&:decorate)
    return [] if @numismatic_monograms.to_a.blank?
  end

  def manifest
    authorize! :manifest, resource
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(resource).build
      end
    end
  end
end
