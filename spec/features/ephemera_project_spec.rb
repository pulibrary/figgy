# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Ephemera Project" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  scenario "editing a project", js: true do
    project = FactoryBot.create_for_repository(:ephemera_project)
    visit edit_ephemera_project_path(id: project.id)

    # renders rich text editor for description
    element = find("trix-editor > div")
    expect(element.text).to eq project.description.first
  end
end
