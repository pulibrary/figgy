# frozen_string_literal: true
class GeoserverMessageGenerator
  attr_reader :resource

<<<<<<< HEAD
  # @param resource [Valkyrie::Resource]
=======
>>>>>>> d8616123... adds lux order manager to figgy
  def initialize(resource:)
    @resource = resource
  end

<<<<<<< HEAD
  # Generate the (RabbitMQ) message propagated in response to a new geospatial
  #   asset being ingested or updated
  # @return [Hash]
=======
>>>>>>> d8616123... adds lux order manager to figgy
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

<<<<<<< HEAD
    # GeoServer workspace for restricted content that requires authentication
    # @return [String]
    def authenticated_workspace
      Figgy.config["geoserver"]["authenticated"]["workspace"]
    end

    # Generate the file path for the first derivative appended to the resource
    # @return [String]
    def derivative_file_path
      derivative_id = resource.derivative_file.file_identifiers.first
      Valkyrie::StorageAdapter.find_by(id: derivative_id).io.path
    rescue Valkyrie::StorageAdapter::FileNotFound
      return ""
    end

    # Access the path used for GeoServer derivatives
    # @return [String]
=======
    def derivative_file_path
      derivative_id = resource.derivative_file.file_identifiers[0]
      Valkyrie::StorageAdapter.find_by(id: derivative_id).io.path
    end

>>>>>>> d8616123... adds lux order manager to figgy
    def geotiff_path
      derivative_file_path.gsub(Figgy.config["geo_derivative_path"], geoserver_base_path)
    end

<<<<<<< HEAD
    # Access the currently configured path for GeoServer derivative files
    # @return [String]
=======
>>>>>>> d8616123... adds lux order manager to figgy
    def geoserver_base_path
      Figgy.config["geoserver"]["derivatives_path"]
    end

<<<<<<< HEAD
    # Resource id prefixed with letter to avoid restrictions on
    # numbers in QNames from GeoServer generated WFS GML.
    # @return [String]
    def id
      "p-#{resource.id}"
    end

    # Provide the type of geospatial layer type (Shapefile or GeoTIFF)
    # @return [Symbol]
    def layer_type
      return :shapefile if vector_file?
      :geotiff
    end

    # Retrieve the parent resource
    # @return [Valkyrie::Resource]
=======
    def id
      resource.id.to_s
    end

    def layer_type
      return :shapefile if vector_resource_parent?
      :geotiff
    end

>>>>>>> d8616123... adds lux order manager to figgy
    def parent
      @parent ||= resource.decorate.parent
    end

<<<<<<< HEAD
    # Generate the file system path for the vector shapefile binary or raster
    #   GeoTiff
    # @return [String]
    def path
      return shapefile_path if vector_file?
      geotiff_path
    end

    # GeoServer workspace for open public content
    # @return [String]
    def public_workspace
      Figgy.config["geoserver"]["open"]["workspace"]
    end

    # Provide the default public visibility value for the resource
    # @return [String]
=======
    def path
      return shapefile_path if vector_resource_parent?
      geotiff_path
    end

>>>>>>> d8616123... adds lux order manager to figgy
    def public_visibility
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

<<<<<<< HEAD
    # Generate the file system path for the Shapefile (comprising a vector
    #   dataset)
    # @return [String]
=======
>>>>>>> d8616123... adds lux order manager to figgy
    def shapefile_path
      "file://#{File.dirname(geotiff_path)}/#{File.basename(geotiff_path, '.zip')}/#{id}.shp"
    end

<<<<<<< HEAD
    # Retrieve the title from the parent resource
    # @return [String]
    def title
      return "" unless parent
      Array(parent.title).first.to_s
    end

    # Determines whether or the resource is a vector file
    # @return [Boolean]
    def vector_file?
      ControlledVocabulary::GeoVectorFormat.new.include?(resource.mime_type.first)
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
=======
    def title
      Array(resource.decorate.parent.title).first.to_s
    end

    def vector_resource_parent?
      parent.is_a?(VectorResource)
    end

    def workspace
      visibility = parent.model.visibility.try(:first)
      return Figgy.config["geoserver"]["open"]["workspace"] if visibility == public_visibility
      Figgy.config["geoserver"]["authenticated"]["workspace"]
>>>>>>> d8616123... adds lux order manager to figgy
    end
end
