# frozen_string_literal: true

class BoxWorkflow
  include AASM

  def initialize(state)
    aasm.current_state = state.to_sym unless state.nil?
  end

  aasm do
    state :new, initial: true
    state :ready_to_ship
    state :shipped
    state :received
    state :all_in_production

    # ingest workflow
    event :ready_to_ship do
      transitions from: :new, to: :ready_to_ship
    end
    event :shipped do
      transitions from: :ready_to_ship, to: :shipped
    end
    event :received do
      transitions from: :shipped, to: :received
    end
    event :all_in_production do
      transitions from: :received, to: :all_in_production
    end
  end

  def suppressed?
    false
  end

  def valid_states
    aasm.states.map(&:name).map(&:to_s)
  end

  def valid_transitions
    aasm.states(permitted: true).map(&:name).map(&:to_s)
  end
end
