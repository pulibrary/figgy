# frozen_string_literal: true

class BoxBoxlessFoldersJob < ApplicationJob
  def perform(project_id:, box_id:)
    project = query_service.find_by(id: project_id)
    box = query_service.find_by(id: box_id)
    member_ids_to_move = Wayfinder.for(project).ephemera_folders.map(&:id)

    project_change_set = ChangeSet.for(project)
    project_change_set.validate(
      member_ids: project_change_set.member_ids - member_ids_to_move
    )
    change_set_persister.save(change_set: project_change_set)

    box_change_set = ChangeSet.for(box)
    box_change_set.validate(
      member_ids: box_change_set.member_ids + member_ids_to_move
    )
    change_set_persister.save(change_set: box_change_set)
  end

  private

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.default
    end

    def query_service
      change_set_persister.query_service
    end
end
