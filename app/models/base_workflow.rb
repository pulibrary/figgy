# frozen_string_literal: true

class BaseWorkflow
  include AASM

  def self.valid_states_for_classes
    {}
  end

  def self.state_for_related(klass:, state:)
    state
  end

  def initialize(state = nil)
    aasm.current_state = state.to_sym unless state.nil?
  end

  def valid_states
    aasm.states.map(&:name).map(&:to_s)
  end

  def valid_transitions
    aasm.states(permitted: true).map(&:name).map(&:to_s)
  end

  def self.public_read_states
    []
  end

  def self.manifest_states
    []
  end

  # States in which an ark can be minted for the record
  # @return [Array<String>] the states for which an ARK can be minted
  def self.ark_mint_states
    []
  end
end
