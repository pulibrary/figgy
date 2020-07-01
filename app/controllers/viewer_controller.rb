# frozen_string_literal: true

class ViewerController < ApplicationController
  layout "viewer_layout"
  def index
    render :index
  end

  def auth
    resource = query_service.find_by(id: params[:id])
    return redirect_to_viewer(resource) if current_user
    if can?(:discover, resource)
      render :auth
    else
      redirect_to_viewer(resource)
    end
  end

  def redirect_to_viewer(resource)
    redirect_to viewer_index_path(anchor: "?manifest=#{manifest_helper.manifest_url(resource)}")
  end

  def manifest_helper
    ManifestBuilder::ManifestHelper.new
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
