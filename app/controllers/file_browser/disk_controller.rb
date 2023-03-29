# frozen_string_literal: true
class FileBrowser::DiskController < ApplicationController
  def index
    authorize! :create, ScannedResource
    respond_to do |format|
      format.json do
        render json: FileBrowserDiskProvider.new(root: Figgy.config["ingest_folder_path"])
      end
    end
  end

  def show
    authorize! :create, ScannedResource
    respond_to do |format|
      format.json do
        render json: FileBrowserDiskProvider.new(root: Figgy.config["ingest_folder_path"], base: CGI.unescape(params[:id]))
      end
    end
  end
end
