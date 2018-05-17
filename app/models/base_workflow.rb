# frozen_string_literal: true

class BaseWorkflow
  include AASM

  class << self
      # Retrieve the state for the resource
      # @param klass [Symbol] the related resource using a different workflow
      # @param state [Symbol] the state of the related resource using a different workflow
      # @return [String] the folder workflow state corresponding to the workflow state of the related resource
      def state_for_related(klass:, state:)
        state
      end

    private

      # Generate the mapping for workflow states of relatable resource classes to those in the folder workflow
      # @return Hash{Symbol => Hash{Symbol => Symbol}}
      def valid_states_for_classes
        {}
      end
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
