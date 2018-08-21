# frozen_string_literal: true

# State-based workflow for folders: Start at requiring QA (will be visible, but
# not able to view the manifest.) When complete, the manifest is visible.
class FolderWorkflow < BaseWorkflow
  aasm do
    state :needs_qa, initial: true
    state :complete

    # ingest workflow
    event :make_complete do
      transitions from: :needs_qa, to: :complete
    end
    event :submit_for_qa do
      transitions from: :complete, to: :needs_qa
    end
  end

  # Translates the state of another workflow to correspond to the current state of this workflow
  # @param workflow [BaseWorkflow]
  # @return [Symbol]
  def translate_state_from(workflow)
    return super if workflow.class == self.class
    final_state if workflow.final_state?
  end

  # States in which the record can be publicly viewable
  # All states must be included here because any state is viewable if its container allows it
  # @return array of strings
  def self.public_read_states
    [:needs_qa, :complete].map(&:to_s)
  end

  # States in which read groups for the record are indexable
  # Folders are consulted and will override this if appropriate
  # @return [Array<String>]
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
