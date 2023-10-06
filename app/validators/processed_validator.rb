# frozen_string_literal: true
class ProcessedValidator < ActiveModel::Validator
  def validate(record)
    workflow = record.workflow_class.new(record.old_state)
    if workflow.final_state? || record.new_state != workflow.final_state.to_s
      true
    elsif InProcessOrPending.for(record)
      record.errors.add :state, "Can't complete record while still in process"
    end
  end
end
