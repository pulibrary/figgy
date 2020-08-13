# frozen_string_literal: true

class ViewerController < ApplicationController
  layout "viewer_layout"
  after_action :allow_iframe

  def index
    render :index
  end

  def auth
    @charge_manager = CDL::ChargeManager.new(resource_id: params[:id], eligible_item_service: CDL::EligibleItemService, change_set_persister: change_set_persister)
    return cdl_check(@charge_manager) if current_user
    if can?(:discover, @charge_manager.resource)
      render :auth
    else
      redirect_to_viewer(@charge_manager.resource)
    end
  end

  def restricted_viewership?
    collections = Wayfinder.for(@charge_manager.resource).try(:collections) || []
    collections.flat_map(&:restricted_viewers).present?
  end
  helper_method :restricted_viewership?

  def cdl_check(charge_manager)
    if can?(:read, charge_manager.resource)
      redirect_to_viewer(charge_manager.resource)
    elsif charge_manager.eligible?
      render :cdl_checkout
    else
      # This only happens if the user has manually gone to this URL.
      redirect_to_viewer(charge_manager.resource)
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
