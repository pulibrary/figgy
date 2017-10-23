# frozen_string_literal: true
class EphemeraBoxDecorator < Valkyrie::ResourceDecorator
  display(
    [
      :barcode,
      :box_number,
      :shipped_date,
      :tracking_number,
      :visibility,
      :member_of_collections
    ]
  )

  def title
    "Box #{box_number.first}"
  end

  def members
    @members ||= query_service.find_members(resource: model).to_a
  end

  def folders
    @folders ||= members.select { |r| r.is_a?(EphemeraFolder) }.map(&:decorate).to_a
  end

  def ephemera_projects
    @ephemera_projects ||= query_service.find_parents(resource: model).map(&:decorate).to_a
  end

  def collection_slugs
    @collection_slugs ||= ephemera_projects.map(&:slug)
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

  def rendered_state
    ControlledVocabulary.for(:state_box_workflow).badge(state)
  end

  def state
    super.first
  end

  def barcode
    super.first
  end
end
