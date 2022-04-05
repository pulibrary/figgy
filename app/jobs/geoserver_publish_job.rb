# frozen_string_literal: true
class GeoserverPublishJob < ApplicationJob
  # queue_as :high
  attr_reader :layer_type, :params

  def perform(event, params)
    @params = params
    @layer_type = params["layer_type"]

    case event
    when "CREATE"
      create
    when "DELETE"
      # Attempt to delete from both public and restricte
      # workspaces to make sure all traces of the file
      # are cleaned up on GeoServer.
      params["workspace"] = public_workspace
      delete
      params["workspace"] = authenticated_workspace
      delete
    when "UPDATE"
      delete
      create
    end
  end

  private

    def create
      Geoserver::Publish.send(create_method, create_params)
    rescue => e
      logger.info("Geoserver publish error: #{e.message}")
    end

    def create_params
      {
        workspace_name: params["workspace"],
        file_path: params["path"],
        id: params["id"],
        title: params["title"]
      }
    end

    def create_method
      return :geotiff if layer_type == "geotiff"
      return :shapefile if layer_type == "shapefile"
    end

    def delete
      Geoserver::Publish.send(delete_method, delete_params)
    rescue => e
      logger.info("Geoserver publish error: #{e.message}")
    end

    def delete_method
      return :delete_geotiff if layer_type == "geotiff"
      return :delete_shapefile if layer_type == "shapefile"
    end

    def delete_params
      {
        workspace_name: params["workspace"],
        id: params["id"]
      }
    end

    def authenticated_workspace
      Figgy.config["geoserver"]["authenticated"]["workspace"]
    end

    def public_workspace
      Figgy.config["geoserver"]["open"]["workspace"]
    end
end
