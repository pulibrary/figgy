# frozen_string_literal: true
class NumismaticIssueDecorator < Valkyrie::ResourceDecorator
  display :artist,
          :color,
          :date_range,
          :denomination,
          :department,
          :description,
          :edge,
          :era,
          :figure,
          :geographic_origin,
          :master,
          :metal,
          :note,
          :object_type,
          :obverse_attributes,
          :obverse_legend,
          :obverse_type,
          :orientation,
          :part,
          :place,
          :references,
          :reverse_attributes,
          :reverse_legend,
          :reverse_type,
          :ruler,
          :series,
          :shape,
          :subject,
          :symbol,
          :visibility,
          :workshop

  delegate :members, :decorated_coins, :coin_count, to: :wayfinder

  # Whether this box has a workflow state that grants access to its contents
  # @return [TrueClass, FalseClass]
  def grant_access_state?
    workflow_class.public_read_states.include? Array.wrap(state).first.underscore
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end

  def attachable_objects
    [Coin]
  end

  def state
    super.first
  end
end
