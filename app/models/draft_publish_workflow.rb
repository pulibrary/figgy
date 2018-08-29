# frozen_string_literal: true

# Simple draft / published state-based workflow: Start as draft (will be
# visible, but not able to view the manifest.) When published, the
# manifest is visible.
class DraftPublishWorkflow < BaseWorkflow
  aasm do
    state :draft, initial: true
    state :published

    # ingest workflow
    event :publish do
      transitions from: :draft, to: :published
    end
    event :unpublish do
      transitions from: :published, to: :draft
    end
  end

  # States in which the record is publicly readable (as allowed by visibility)
  # @return [Array<String>]
  def self.public_read_states
    [:published].map(&:to_s)
  end

  # States in which a manifest can be published for the record
  # @return [Array<String>]
  def self.manifest_states
    [:published].map(&:to_s)
  end

  # States in which an ark can be minted for the record
  # @return [Array<String>] the states for which an ARK can be minted
  def self.ark_mint_states
    [:published].map(&:to_s)
  end
end
