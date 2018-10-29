# frozen_string_literal: true
class NumismaticIssueDecorator < Valkyrie::ResourceDecorator
  display :object_type,
          :denomination,
          :metal,
          :geographic_origin,
          :workshop,
          :ruler,
          :date_range,
          :obverse_type,
          :obverse_legend,
          :obverse_attributes,
          :reverse_type,
          :reverse_legend,
          :reverse_attributes,
          :master,
          :description,
          :references,
          :visibility

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
