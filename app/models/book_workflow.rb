# frozen_string_literal: true

# State-based workflow for books: The primary workflow is to start at pending, and progress through
# metadata_review and final_review to complete.  There are two exceptional workflows: between
# complete/takedown (for issues requiring an item be suppressed), and between complete/flagged (for issues
# where an item can remain accessible).
class BookWorkflow < BaseWorkflow
  aasm do
    state :pending, initial: true
    state :metadata_review
    state :final_review
    state :complete_when_processed
    state :takedown
    state :flagged
    state :complete

    # ingest workflow
    event :finalize_digitization do
      transitions from: :pending, to: :metadata_review
    end
    event :finalize_metadata do
      transitions from: :metadata_review, to: :final_review
    end
    event :make_complete do
      transitions from: :final_review, to: :complete
      transitions from: :pending, to: :complete
      transitions from: :metadata_review, to: :complete
      transitions from: :complete_when_processed, to: :complete
    end

    # takedown/restore workflow
    event :mark_for_takedown do
      transitions from: :complete, to: :takedown
    end
    event :restore do
      transitions from: :takedown, to: :complete
    end

    # flag/unflag workflow
    event :flag do
      transitions from: :complete, to: :flagged
    end
    event :unflag do
      transitions from: :flagged, to: :complete
    end
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

  # States in which the record is publicly readable (as allowed by visilibility)
  # @return [Array<String>]
  def self.public_read_states
    [:complete, :flagged].map(&:to_s)
  end

  # States in which a manifest can be published for the record
  # @return [Array<String>]
  def self.manifest_states
    [:complete, :flagged].map(&:to_s)
  end

  # States in which an ark can be minted for the record
  # @return [Array<String>] the states for which an ARK can be minted
  def self.ark_mint_states
    [:complete].map(&:to_s)
  end
end
