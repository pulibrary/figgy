# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectIndexer do
  describe ".to_solr" do
    it "indexes the project when it's a folder" do
      folder = FactoryBot.create_for_repository(:ephemera_folder)
      box = FactoryBot.create_for_repository(:ephemera_box, member_ids: folder.id)
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: box.id)

      output = described_class.new(resource: folder).to_solr

      expect(output["ephemera_project_ssim"]).to eq project.title
      expect(output["ephemera_project_tesim"]).to eq project.title
    end
    it "indexes the project when it's a box" do
      box = FactoryBot.create_for_repository(:ephemera_box)
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: box.id)

      output = described_class.new(resource: box).to_solr
      expect(output["ephemera_project_ssim"]).to eq project.title
    end
  end
end
