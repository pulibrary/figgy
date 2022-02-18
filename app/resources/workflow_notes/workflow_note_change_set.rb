# frozen_string_literal: true

class WorkflowNoteChangeSet < Valkyrie::ChangeSet
  validates :author, :note, presence: true
  property :note, multiple: false, required: false
  property :author, multiple: false
end
