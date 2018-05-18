# frozen_string_literal: true

class BaseWorkflow
  include AASM

  delegate :current_state, to: :aasm

  def initialize(state = nil)
    aasm.current_state = state.to_sym unless state.nil?
  end

  def final_state
    aasm.states.last.name
  end

  def final_state?
    current_state == final_state
  end

  def translate_state_from(workflow)
    workflow.current_state
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
