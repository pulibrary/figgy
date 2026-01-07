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
      Hydra.config[:permissions][:read].group => read_groups,
      folder_label_tesim: folder_label
    }.tap do |h|
      h[:parent_box_id_ssi] = box_id if box_id
    end
  end

  private

    def folder_label
      box_number.nil? ? "Folder #{folder_number}" : "Box #{box_number} Folder #{folder_number}"
    end

    def box_number
      Array.wrap(decorated.parent.box_number).first if decorated.parent.respond_to?(:box_number)
    end

    def box_id
      decorated.ephemera_box&.id&.to_s
    end

    def folder_number
      Array.wrap(decorated.folder_number).first
    end

    def decorated
      @decorated ||= resource.decorate
    end

    def read_groups
      return resource.read_groups if decorated.index_read_groups?
      []
    end
end
