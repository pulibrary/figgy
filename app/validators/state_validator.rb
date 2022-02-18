# frozen_string_literal: true

class StateValidator < ActiveModel::Validator
  def validate(record)
    validate_state(record)
    validate_transition(record)
  end

  private

    def validate_state(record)
      return if workflow(record).valid_states.include?(record.new_state)
      record.errors.add :state, "#{record.new_state} is not a valid state"
    end

    def validate_transition(record)
      return unless record.state_changed?
      return if workflow(record).valid_transitions.include?(record.new_state)
      record.errors.add :state, "Cannot transition from #{record.old_state} to #{record.new_state}"
    end

    def workflow(record)
      record.workflow_class.new(record.old_state)
    end
end
