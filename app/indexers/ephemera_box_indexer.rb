# frozen_string_literal: true

class EphemeraBoxIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.is_a?(::EphemeraBox)
    {
      "title_tesim" => [decorated.title],
      "title_ssim" => [decorated.title],
      "title_tsim" => [decorated.title]
    }
  end

  private

    def decorated
      @decorated ||= resource.decorate
    end
end
