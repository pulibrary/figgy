# frozen_string_literal: true
class TombstoneIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.is_a?(::Tombstone)
    {
      "title_tesim" => [resource.file_set_title],
      "title_ssim" => [resource.file_set_title],
      "title_tsim" => [resource.file_set_title]
    }
  end
end
