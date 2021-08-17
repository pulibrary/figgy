# frozen_string_literal: true
class ProjectIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.is_a?(EphemeraFolder) || resource.is_a?(EphemeraBox)
    return {} unless project
    {
      "ephemera_project_ssim" => [project.title],
      "ephemera_project_tesim" => [project.title]
    }
  end

  def project
    return unless box
    box.decorate.ephemera_project
  end

  def box
    resource.decorate.ephemera_box
  end
end
