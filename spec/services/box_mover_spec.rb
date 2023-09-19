# frozen_string_literal: true
require "rails_helper"

RSpec.describe BoxMover do
  describe "#move!" do
    it "moves a box to a new project" do
      box = FactoryBot.create_for_repository(:ephemera_box)
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id])
      target_project = FactoryBot.create_for_repository(:ephemera_project)
      expect(Wayfinder.for(box).ephemera_project.id).to eq project.id

      described_class.new(box: box, target_project: target_project).move!

      expect(Wayfinder.for(box).ephemera_project.id).to eq target_project.id
      expect(Wayfinder.for(project).ephemera_boxes.length).to eq 0
      expect(Wayfinder.for(target_project).ephemera_boxes.map(&:id)).to eq [box.id]
    end
  end
end
