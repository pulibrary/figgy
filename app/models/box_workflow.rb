# frozen_string_literal: true

class BoxWorkflow < BaseWorkflow
  aasm do
    state :new, initial: true
    state :ready_to_ship
    state :shipped
    state :received
    state :all_in_production

    # ingest workflow
    event :prepare_to_ship do
      transitions from: :new, to: :ready_to_ship
    end
    event :ship do
      transitions from: :ready_to_ship, to: :shipped
    end
    event :mark_as_received do
      transitions from: :shipped, to: :received
    end
    event :release_into_production do
      transitions from: :received, to: :all_in_production
    end
  end

  # States in which the record should be publicly viewable
  # (boxes are never publicly viewable)
  # @return [Array]
  def self.public_read_states
    []
  end

  # States in which a manifest can be published
  # @return [Array<String>]
  def self.manifest_states
    [:all_in_production].map(&:to_s)
  end

  # states that grant read access to contained items
  # @return [Array<String>]
  def self.grant_access_states
    [:all_in_production].map(&:to_s)
  end

  # States in which an ark can be minted for the record
  # @return [Array<String>] the states for which an ARK can be minted
  def self.ark_mint_states
    []
  end
end
