# frozen_string_literal: true

# State-based workflow for books: The primary workflow is to start at pending, and progress through
# metadata_review and final_review to complete.  There are two exceptional workflows: between
# complete/takedown (for issues requiring an item be suppressed), and between complete/flagged (for issues
# where an item can remain accessible).
class BookWorkflow
  include AASM

  def initialize(state)
    aasm.current_state = state.to_sym unless state.nil?
  end

  aasm do
    state :pending, initial: true
    state :metadata_review
    state :final_review
    state :complete
    state :takedown
    state :flagged

    # ingest workflow
    event :finalize_digitization do
      transitions from: :pending, to: :metadata_review
    end
    event :finalize_metadata do
      transitions from: :metadata_review, to: :final_review
    end
    event :complete do
      transitions from: :final_review, to: :complete
    end

    # takedown/restore workflow
    event :takedown do
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

  def suppressed?
    pending? || metadata_review? || final_review? || takedown?
  end

  def valid_states
    aasm.states.map(&:name).map(&:to_s)
  end

  def valid_transitions
    aasm.states(permitted: true).map(&:name).map(&:to_s)
  end
end
