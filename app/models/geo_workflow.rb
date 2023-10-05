# frozen_string_literal: true

class GeoWorkflow < BaseWorkflow
  aasm do
    state :pending, initial: true
    state :final_review
    state :complete_when_processed
    state :takedown
    state :flagged
    state :complete

    # ingest workflow
    event :finalize_digitization do
      transitions from: :pending, to: :final_review
    end
    event :make_complete do
      transitions from: :pending, to: :complete
      transitions from: :final_review, to: :complete
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

  # States in which the record is publicly readable (as allowed by visibility)
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
