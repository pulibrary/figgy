# frozen_string_literal: true
class GeoserverPublishJob < ApplicationJob
  attr_reader :layer_type, :params

  def perform(event, base_params)
    @params = base_params
    @layer_type = base_params["layer_type"]

    case event
    when "CREATE"
      create_layer
    when "DELETE"
      # Attempt to delete from both public and restricte
      # workspaces to make sure all traces of the file
      # are cleaned up on GeoServer.
      params["workspace"] = public_workspace
      delete_layers
      params["workspace"] = authenticated_workspace
      delete_layers
    when "UPDATE"
      delete_layer
      create_layer
    end
  end

  private

    def create_layer
      Geoserver::Publish.send(create_method, create_params)
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

    def delete_layer
      logger.info("Geoserver delete layer params: #{params}")
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
