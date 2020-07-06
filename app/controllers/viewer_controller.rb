# frozen_string_literal: true

class ViewerController < ApplicationController
  layout "viewer_layout"
  after_action :allow_iframe

  def index
    render :index
  end

  def auth
    @charge_manager = CDL::ChargeManager.new(resource_id: params[:id], eligible_item_service: CDL::EligibleItemService, change_set_persister: change_set_persister)
    return redirect_to_viewer(@charge_manager.resource) if current_user
    if can?(:discover, @charge_manager.resource)
      render :auth
    else
      redirect_to_viewer(@charge_manager.resource)
    end
  end

  def redirect_to_viewer(resource)
    redirect_to viewer_index_path(anchor: "?manifest=#{manifest_helper.manifest_url(resource)}")
  end

  def manifest_helper
    ManifestBuilder::ManifestHelper.new
  end

  def change_set_persister
    ChangeSetPersister.new(
      metadata_adapter: Valkyrie.config.metadata_adapter,
      storage_adapter: Valkyrie.config.storage_adapter
    )
  end

  private

    def allow_iframe
      response.headers.except! "X-Frame-Options"
    end
end
