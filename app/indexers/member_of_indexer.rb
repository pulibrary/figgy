# frozen_string_literal: true
class MemberOfIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless index_as_member?
    {
      "member_of_ssim" => parents.map { |x| "id-#{x.id}" }.to_a
    }
  end

  def index_as_member?
    resource.is_a?(ScannedResource) || resource.is_a?(ScannedMap) || raster_set_member
  end

  def parents
    @parents ||=
      query_service.find_parents(resource: resource)
  rescue ArgumentError
    @parents = []
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end

  def raster_set_member
    return false unless resource.is_a?(RasterResource)
    parents.first.is_a?(RasterResource) || parents.first.is_a?(ScannedMap)
  end
end
