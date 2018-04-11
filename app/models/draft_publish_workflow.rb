# frozen_string_literal: true

# Simple draft / published state-based workflow: Start as draft (will be
# visible, but not able to view the manifest.) When published, the
# manifest is visible.
class DraftPublishWorkflow
  include AASM

  def initialize(state)
    aasm.current_state = state.to_sym unless state.nil?
  end

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

  # this workflow doesn't have a suppressed state but other code checks for it; make it false
  def suppressed?
    false
  end

  def valid_states
    aasm.states.map(&:name).map(&:to_s)
  end

  def valid_transitions
    aasm.states(permitted: true).map(&:name).map(&:to_s)
  end
end
