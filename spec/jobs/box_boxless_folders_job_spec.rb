# frozen_string_literal: true
require "rails_helper"

RSpec.describe BoxBoxlessFoldersJob do
  describe ".perform" do
    it "Adds the folders to the box" do
      # 2 folders with no box
      folder2 = FactoryBot.create_for_repository(:complete_ephemera_folder)
      folder3 = FactoryBot.create_for_repository(:complete_ephemera_folder)
      # new box to hold the folders without boxes, one folder already added
      folder1 = FactoryBot.create_for_repository(:complete_ephemera_folder)
      box0 = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder1.id])
      # pre-existing box with folder
      folder4 = FactoryBot.create_for_repository(:complete_ephemera_folder)
      box1 = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder4.id])
      project = FactoryBot.create_for_repository(
        :ephemera_project,
        member_ids: [folder2.id, folder3.id, box0.id, box1.id]
      )
      expect(Wayfinder.for(project).ephemera_folders.count).to eq 2
      expect(Wayfinder.for(box0).ephemera_folders.count).to eq 1

      described_class.perform_now(project_id: project.id, box_id: box0.id)

      project = query_service.find_by(id: project.id)
      box0 = query_service.find_by(id: box0.id)

      expect(Wayfinder.for(box0).ephemera_folders.count).to eq 3
      expect(Wayfinder.for(box1).ephemera_folders.count).to eq 1
      expect(Wayfinder.for(project).ephemera_folders.count).to eq 0
      expect(Wayfinder.for(project).ephemera_boxes.count).to eq 2
    end
  end

  def query_service
    ChangeSetPersister.default.query_service
  end
end
