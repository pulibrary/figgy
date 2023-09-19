# frozen_string_literal: true
class BoxMover
  attr_reader :box, :target_project, :change_set_persister
  def initialize(box:, target_project:, change_set_persister: ChangeSetPersister.default)
    @box = box
    @target_project = target_project
    @change_set_persister = change_set_persister
  end

  def move!
    change_set = ChangeSet.for(box)
    change_set.append_id = target_project.id
    change_set_persister.save(change_set: change_set)
  end
end
