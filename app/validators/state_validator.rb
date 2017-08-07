# frozen_string_literal: true
class StateValidator < ActiveModel::Validator
  def validate(record)
    validate_state(record)
    validate_transition(record)
  end

  private

    def validate_state(record)
      return if workflow(record).valid_states.include?(new_state(record))
      record.errors.add :state, "#{new_state(record)} is not a valid state"
    end

    def validate_transition(record)
      return unless record.changed?(:state) && !old_state(record).nil? && old_state(record) != new_state(record)
      return if workflow(record).valid_transitions.include?(new_state(record))
      record.errors.add :state, "Cannot transition from #{old_state(record)} to #{new_state(record)}"
    end

    def workflow(record)
      record.workflow_class.new(old_state(record))
    end

    def new_state(record)
      Array.wrap(record.state).first
    end

    def old_state(record)
      Array.wrap(record.model.state).first
    end
end
