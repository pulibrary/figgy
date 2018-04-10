# frozen_string_literal: true
class WorkflowNoteDecorator < Valkyrie::ResourceDecorator
  def note
    super.first
  end

  def author
    super.first
  end
end
