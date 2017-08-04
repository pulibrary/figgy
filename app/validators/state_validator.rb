class StateValidator < ActiveModel::Validator
  def validate(record)
    validate_state(record)
    validate_transition(record)
  end

  private

    def validate_state(record)
      return unless workflow(record).valid_states.include?(record.state)
      record.errors.add :state, "#{record.state} is not a valid state"
    end

    def validate_transition(record)
      return unless record.changed?(:state) && !record.model.state.first.nil? && record.state != record.model.state.first
      return if workflow(record).valid_transitions.include?(record.state)
      record.errors.add :state, "Cannot transition from #{record.model.state.first} to #{record.state}"
    end

    def workflow(record)
      record.workflow_class.new(record.model.state.first)
    end
end
