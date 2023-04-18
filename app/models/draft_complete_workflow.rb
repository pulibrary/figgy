# frozen_string_literal: true

# Simple draft / completed state-based workflow: Start as draft (will be
# visible, but not able to view the manifest.) When completed, the
# manifest is visible.
class DraftCompleteWorkflow < BaseWorkflow
  aasm do
    state :draft, initial: true
    state :complete_when_processed
    state :complete

    # ingest workflow
    event :make_complete do
      transitions from: :draft, to: :complete
      transitions from: :complete_when_processed, to: :complete
    end
    event :make_draft do
      transitions from: :complete, to: :draft
    end
  end

  # States in which the record is publicly readable (as allowed by visibility)
  # @return [Array<String>]
  def self.public_read_states
    [:complete].map(&:to_s)
  end

  # States in which a manifest can be completed for the record
  # @return [Array<String>]
  def self.manifest_states
    [:complete].map(&:to_s)
  end

  # States in which an ark can be minted for the record
  # @return [Array<String>] the states for which an ARK can be minted
  def self.ark_mint_states
    [:complete].map(&:to_s)
  end
end
