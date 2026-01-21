class WorkflowNoteDecorator < Valkyrie::ResourceDecorator
  def note
    super.first
  end

  def author
    super.first
  end
end
