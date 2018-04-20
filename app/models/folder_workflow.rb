# frozen_string_literal: true

# State-based workflow for folders: Start at requiring QA (will be visible, but
# not able to view the manifest.) When complete, the manifest is visible.
class FolderWorkflow
  include AASM

  def initialize(state)
    aasm.current_state = state.to_sym unless state.nil?
  end

  aasm do
    state :needs_qa, initial: true
    state :complete

    # ingest workflow
    event :complete do
      transitions from: :needs_qa, to: :complete
    end
    event :submit_for_qa do
      transitions from: :complete, to: :needs_qa
    end
  end

  def valid_states
    aasm.states.map(&:name).map(&:to_s)
  end

  def valid_transitions
    aasm.states(permitted: true).map(&:name).map(&:to_s)
  end

  # States in which the record can be publicly viewable
  # All states must be included here because any state is viewable if its container allows it
  # @return array of strings
  def self.public_read_states
    [:needs_qa, :complete].map(&:to_s)
  end

  # States in which read groups for the record are indexable
  # Folders are consulted and will override this if appropriate
  def self.index_read_groups_states
    [:complete].map(&:to_s)
  end

  # States in which a manifest can be published for the record
  # Note that a folder manifest should be published in any state if it is contained
  # by a box with state 'all_in_production'
  # @return array of strings
  def self.manifest_states
    [:complete].map(&:to_s)
  end

  # States in which an ark can be minted for the record
  # @return [Array<String>] the states for which an ARK can be minted
  def self.ark_mint_states
    []
  end
end
