# frozen_string_literal: true
class EphemeraBoxDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [
    :barcode,
    :box_number,
    :shipped_date,
    :tracking_number,
    :member_of_collections,
    :visibility
  ]

  self.iiif_manifest_attributes = []
  delegate :query_service, to: :metadata_adapter

  def member_of_collections
    @member_of_collections ||=
      begin
        query_service.find_references_by(resource: model, property: :member_of_collection_ids)
                     .map(&:decorate)
                     .map(&:title).to_a
      end
  end

  def members
    @members ||= query_service.find_members(resource: model)
  end

  def folders
    @folders ||= members.select { |r| r.is_a?(EphemeraFolder) }.map(&:decorate).to_a
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end

  def attachable_objects
    [EphemeraFolder]
  end
end
