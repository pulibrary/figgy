# frozen_string_literal: true

class BaseWorkflow
  include AASM

  delegate :current_state, to: :aasm

  # Constructor
  # @param state [String,Symbol,nil] the initial state for the workflow
  def initialize(state = nil)
    aasm.current_state = state.to_sym unless state.nil?
  end

  # Final state for the workflow
  # @return [Symbol]
  def final_state
    aasm.states.last.name
  end

  # Determines whether or not this workflow is in its final state
  # @return [TrueClass, FalseClass]
  def final_state?
    current_state == final_state
  end

  # Translates the state of another workflow to correspond to the current state of this workflow
  # @param workflow [BaseWorkflow]
  # @return [Symbol]
  def translate_state_from(workflow)
    workflow.current_state
  end

  # Retrieve all valid states for this workflow
  # @return [Array<String>]
  def valid_states
    aasm.states.map(&:name).map(&:to_s)
  end

  # Retrieve all valid state transitions for this workflow
  # @return [Array<String>]
  def valid_transitions
    aasm.states(permitted: true).map(&:name).map(&:to_s)
  end

  # Retrieve all states for public read-only access for this workflow
  # @return [Array]
  def self.public_read_states
    []
  end

  # Retrieve all states for public read-only IIIF Manifest generation for this workflow
  # @return [Array]
  def self.manifest_states
    []
  end

  # States in which an ark can be minted for the record
  # @return [Array<String>] the states for which an ARK can be minted
  def self.ark_mint_states
    []
  end
end
