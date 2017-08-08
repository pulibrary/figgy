# frozen_string_literal: true
class MemberOfIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    {
      "member_of_ssim" => parents.map { |x| "id-#{x.id}" }.to_a
    }
  end

  def parents
    @parents ||=
      query_service.find_parents(resource: resource)
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end
end
