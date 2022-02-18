# frozen_string_literal: true

class ProcessedEventChangeSet < Valkyrie::ChangeSet
  validates :event_id, presence: true
  property :event_id, multiple: false, required: true
end
