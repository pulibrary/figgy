class FileBrowser::DiskController < ApplicationController
  def index
    authorize! :create, ScannedResource
    respond_to do |format|
      format.json do
        render json: FileBrowserDiskProvider.new(root: Figgy.config["ingest_folder_path"], entry_type: entry_type)
      end
    end
  end

  def show
    authorize! :create, ScannedResource
    respond_to do |format|
      format.json do
        render json: FileBrowserDiskProvider.new(root: Figgy.config["ingest_folder_path"], base: CGI.unescape(params[:id]), entry_type: entry_type)
      end
    end
  end

  private

    def entry_type
      return "default" unless allowed_entry_types.include? params[:entry_type]
      params[:entry_type]
    end

    def allowed_entry_types
      ["default", "selene"]
    end
end
