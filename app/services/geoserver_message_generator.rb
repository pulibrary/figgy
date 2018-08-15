# frozen_string_literal: true
class GeoserverMessageGenerator
  attr_reader :resource

  # @param resource [Valkyrie::Resource]
  def initialize(resource:)
    @resource = resource
  end

  # Generate the (RabbitMQ) message propagated in response to a new geospatial
  #   asset being ingested or updated
  # @return [Hash]
  def generate
    {
      "id" => id,
      "layer_type" => layer_type,
      "workspace" => workspace,
      "path" => path,
      "title" => title
    }
  end

  private

    # Generate the file path for the first derivative appended to the resource
    # @return [String]
    def derivative_file_path
      derivative_id = resource.derivative_file.file_identifiers.first
      Valkyrie::StorageAdapter.find_by(id: derivative_id).io.path
    end

    # Access the path used for GeoServer derivatives
    # @return [String]
    def geotiff_path
      derivative_file_path.gsub(Figgy.config["geo_derivative_path"], geoserver_base_path)
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

    # Provide the type of geospatial layer type (Shapefile or GeoTIFF)
    # @return [Symbol]
    def layer_type
      return :shapefile if vector_resource_parent?
      :geotiff
    end

    # Retrieve the parent resource
    # @return [Valkyrie::Resource]
    def parent
      raise(Valkyrie::Persistence::ObjectNotFoundError, "Failed to retrieve the parent resource for the FileSet #{resource.id}") if resource.decorate.parent.nil?
      @parent ||= resource.decorate.parent
    end

    # Generate the file system path for the vector shapefile binary or raster
    #   GeoTiff
    # @return [String]
    def path
      return shapefile_path if vector_resource_parent?
      geotiff_path
    end

    # Provide the default public visibility value for the resource
    # @return [String]
    def public_visibility
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    # Generate the file system path for the Shapefile (comprising a vector
    #   dataset)
    # @return [String]
    def shapefile_path
      "file://#{File.dirname(geotiff_path)}/#{File.basename(geotiff_path, '.zip')}/#{id}.shp"
    end

    # Retrieve the title from the parent resource
    # @return [String]
    def title
      Array(parent.title).first.to_s
    end

    # Determines whether or not a vector resource is the parent of the current
    #   resource
    # @return [Boolean]
    def vector_resource_parent?
      parent.is_a?(VectorResource)
    end

    # Retrieve the GeoServer workspace using the visibility from the parent
    #   resource
    # @see http://docs.geoserver.org/stable/en/user/rest/workspaces.html
    # @return [String]
    def workspace
      visibility = parent.model.visibility.try(:first)
      return Figgy.config["geoserver"]["open"]["workspace"] if visibility == public_visibility
      Figgy.config["geoserver"]["authenticated"]["workspace"]
    end
end
