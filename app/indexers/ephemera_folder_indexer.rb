# frozen_string_literal: true
class EphemeraFolderIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.is_a?(::EphemeraFolder)
    {
      Hydra.config[:permissions][:read].group => read_groups
    }
  end

  private

    def read_groups
      return [] unless decorated.state == 'complete' && (decorated.ephemera_box.blank? || decorated.ephemera_box.try(:state) == 'all_in_production')
      resource.read_groups
    end

    def decorated
      @decorated ||= resource.decorate
    end
end
