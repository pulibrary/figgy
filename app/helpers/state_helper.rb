# frozen_string_literal: true
module StateHelper
  def valid_states(object)
    object.workflow_class.new(object.state).valid_transitions.unshift(object.state)
  end
end
