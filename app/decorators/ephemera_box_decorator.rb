# frozen_string_literal: true
class EphemeraBoxDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [
    :barcode,
    :box_number,
    :shipped_date,
    :tracking_number,
    :visibility,
    :member_of_collections
  ]

  self.iiif_manifest_attributes = []

  def title
    "Box #{box_number.first}"
  end

  def members
    @members ||= query_service.find_members(resource: model)
  end

  def folders
    @folders ||= members.select { |r| r.is_a?(EphemeraFolder) }.map(&:decorate).to_a
  end

  def ephemera_project
    @ephemera_box ||= query_service.find_parents(resource: model).to_a.first.try(:decorate) || NullProject.new
  end

  class NullProject
    def title; end

    def header
      nil
    end

    def templates
      []
    end

    def nil?
      true
    end
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
