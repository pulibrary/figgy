# frozen_string_literal: true
class CollectionsController < ApplicationController
  include Valhalla::ResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = Collection
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def manifest
    @resource = find_resource(params[:id])
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(@resource).build
      end
    end
  end

  def index_manifest
    @resource = IndexCollection.new
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(@resource).build
      end
    end
  end
end
