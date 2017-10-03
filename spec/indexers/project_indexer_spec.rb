# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ProjectIndexer do
  describe ".to_solr" do
    it "indexes the project when it's a folder" do
      folder = FactoryGirl.create_for_repository(:ephemera_folder)
      box = FactoryGirl.create_for_repository(:ephemera_box, member_ids: folder.id)
      project = FactoryGirl.create_for_repository(:ephemera_project, member_ids: box.id)

      output = described_class.new(resource: folder).to_solr
      expect(output["ephemera_project_ssim"]).to eq project.title
    end
    it "indexes the project when it's a box" do
      box = FactoryGirl.create_for_repository(:ephemera_box)
      project = FactoryGirl.create_for_repository(:ephemera_project, member_ids: box.id)

      output = described_class.new(resource: box).to_solr
      expect(output["ephemera_project_ssim"]).to eq project.title
    end
  end
end
