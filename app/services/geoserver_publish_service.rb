# frozen_string_literal: true
class GeoserverPublishService
  attr_reader :resource, :logger

  # @param resource [FileSet]
  def initialize(resource:, logger: Logger.new(STDOUT))
    @resource = resource
    @logger = logger
  end

  def create
    Geoserver::Publish.send(create_method, create_params)
  end

  def delete
    delete_layer
  end

  def update
    delete_from_all
    create
  end

  private

    def create_method
      layer_type.to_sym
    end

    def create_params
      {
        workspace_name: workspace,
        file_path: path,
        id: id,
        title: title
      }
    end

    def delete_method
      "delete_#{layer_type}".to_sym
    end

    def delete_params
      {
        workspace_name: workspace,
        id: id
      }
    end

    def delete_layer(workspace = nil)
      updated_params = delete_params
      updated_params[:workspace_name] = workspace if workspace
      Geoserver::Publish.send(delete_method, updated_params)
    rescue StandardError => e
      logger.info(e.message)
    end

    def delete_from_all
      # Attempt to delete from both public and restricte
      # workspaces to make sure all traces of the file
      # are cleaned up on GeoServer.
      delete_layer(public_workspace)
      delete_layer(authenticated_workspace)
    end

    # GeoServer workspace for restricted content that requires authentication
    # @return [String]
    def authenticated_workspace
      Figgy.config["geoserver"]["authenticated"]["workspace"]
    end

    # Generate the file path for the first derivative appended to the resource
    # @return [String]
    def derivative_file_path
      local_derivative = resource.derivative_files.find do |derivative_file|
        derivative_file.file_identifiers.first.to_s.include?(Figgy.config["geo_derivative_path"])
      end
      derivative_id = local_derivative.file_identifiers.first
      Valkyrie::StorageAdapter.find_by(id: derivative_id).io.path
    end

    # Access the currently configured path for GeoServer derivative files
    # @return [String]
    def geoserver_base_path
      Figgy.config["geoserver"]["derivatives_path"]
    end

    # Resource id prefixed with letter to avoid restrictions on
    # numbers in QNames from GeoServer generated WFS GML.
    # @return [String]
    def id
      "p-#{resource.id}"
    end

    # Provide the type of geospatial layer type
    # @return [String]
    def layer_type
      return "geotiff" if parent.model.is_a?(RasterResource)
      "shapefile"
    end

    # Retrieve the parent resource
    # @return [Valkyrie::Resource]
    def parent
      @parent ||= resource.decorate.parent
    end

    # Generate the file system path for the vector shapefile binary
    # @return [String]
    def path
      shapefile_path
    end

    # GeoServer workspace for open public content
    # @return [String]
    def public_workspace
      Figgy.config["geoserver"]["open"]["workspace"]
    end

    # Provide the default public visibility value for the resource
    # @return [String]
    def public_visibility
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    # Generate the file system path for the Shapefile (comprising a vector dataset)
    # @return [String]
    def shapefile_path
      base_path = derivative_file_path.gsub(Figgy.config["geo_derivative_path"], geoserver_base_path)
      "file://#{File.dirname(base_path)}/#{File.basename(base_path, '.zip')}/#{id}.shp"
    end

    # Retrieve the title from the parent resource
    # @return [String]
    def title
      return "" unless parent
      Array(parent.title).first.to_s
    end

    # Generate a GeoServer workspace for the file set
    # @see http://docs.geoserver.org/stable/en/user/rest/workspaces.html
    # @return [String]
    def workspace
      # Return a default workspace value if there is no parent resource
      return authenticated_workspace unless parent
      # Generate a workspace value from the visibility of the parent resource
      visibility = parent.model.visibility.try(:first)
      visibility == public_visibility ? public_workspace : authenticated_workspace
    end
end
