# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Structure Manager" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  # we think there's a race condition that may prevent structure nodes from getting cleaned up
  context "When the structure proxy was deleted and not cleaned up" do
    scenario "users visit the structure manager interface" do
      child1 = FactoryBot.create_for_repository(:scanned_resource, title: ["child1"])
      structure = {
        "label": "Top!",
        "nodes": [
          { "label": "Chapter 1",
            "nodes": [
              { "proxy": child1.id }
            ] },
          { "label": "Chapter 2",
            "nodes": [
              { "proxy": "foobar" }
            ] }
        ]
      }
      parent = FactoryBot.create_for_repository(:scanned_resource, logical_structure: [structure], member_ids: [child1.id])

      visit structure_scanned_resource_path(id: parent.id)
      expect(page).to have_http_status(:ok)
    end
  end
end
