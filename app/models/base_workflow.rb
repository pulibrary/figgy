# frozen_string_literal: true

class BaseWorkflow
  class InvalidTranslation < AASM::InvalidTransition; end

  include AASM

  # Generate the mapping for workflow states of relatable resource classes to those in the folder workflow
  # @return Hash{Symbol => Hash{Symbol => Symbol}}
  def self.state_translations
    {}
  end

  delegate :current_state, to: :aasm

  def initialize(state = nil)
    aasm.current_state = state.to_sym unless state.nil?
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
