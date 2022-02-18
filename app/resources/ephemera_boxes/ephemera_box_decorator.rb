# frozen_string_literal: true

class EphemeraBoxDecorator < Valkyrie::ResourceDecorator
  display :barcode,
    :box_number,
    :shipped_date,
    :tracking_number,
    :drive_barcode,
    :visibility,
    :member_of_collections

  def title
    "Box #{box_number.first}"
  end

  delegate :members, :decorated_folders_with_genres, to: :wayfinder

  # TODO: Rename to decorated_ephemera_folders
  def folders
    wayfinder.decorated_ephemera_folders
  end

  # TODO: Rename to ephemera_folders_count
  def folders_count
    wayfinder.ephemera_folders_count
  end

  # TODO: Rename to decorated_ephemera_projects
  def ephemera_projects
    wayfinder.decorated_ephemera_projects
  end

  def collection_slugs
    @collection_slugs ||= ephemera_projects.map(&:slug)
  end

  def ephemera_project
    ephemera_projects.first || NullProject.new
  end

  # Whether this box has a workflow state that grants access to its contents
  # @return [TrueClass, FalseClass]
  def grant_access_state?
    workflow_class.grant_access_states.include? Array.wrap(state).first.underscore
  end

  class NullProject
    def title
    end

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

  def drive_barcode
    super.first
  end

  def barcode
    super.first
  end
end
