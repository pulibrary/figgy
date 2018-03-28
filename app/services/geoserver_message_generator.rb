# frozen_string_literal: true
class GeoserverMessageGenerator
  attr_reader :resource

  def initialize(resource:)
    @resource = resource
  end

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

    def derivative_file_path
      derivative_id = resource.derivative_file.file_identifiers[0]
      Valkyrie::StorageAdapter.find_by(id: derivative_id).io.path
    end

    def geotiff_path
      derivative_file_path.gsub(Figgy.config['geo_derivative_path'], geoserver_base_path)
    end

    def geoserver_base_path
      Figgy.config['geoserver']['derivatives_path']
    end

    def id
      resource.id.to_s
    end

    def layer_type
      return :shapefile if vector_work_parent?
      :geotiff
    end

    def parent
      @parent ||= resource.decorate.parent
    end

    def path
      return shapefile_path if vector_work_parent?
      geotiff_path
    end

    def public_visibility
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    def shapefile_path
      "file://#{File.dirname(geotiff_path)}/#{File.basename(geotiff_path, '.zip')}/#{id}.shp"
    end

    def title
      Array(resource.decorate.parent.title).first.to_s
    end

    def vector_work_parent?
      parent.is_a?(VectorWork)
    end

    def workspace
      visibility = parent.model.visibility.try(:first)
      return Figgy.config['geoserver']['open']['workspace'] if visibility == public_visibility
      Figgy.config['geoserver']['authenticated']['workspace']
    end
end
