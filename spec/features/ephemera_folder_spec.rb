# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Ephemera Folder" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  scenario "multiple descriptions", js: true do
    folder = FactoryBot.create_for_repository(:ephemera_folder)
    visit edit_ephemera_folder_path(id: folder.id)

    description_elements = all(".form-group .ephemera_folder_description")
    expect(description_elements.count).to eq 2
    description_elements.last.fill_in(with: "another description")

    click_button("Add another Description")
    description_elements = all(".form-group .ephemera_folder_description")
    expect(description_elements.count).to eq 3
    description_elements.last.fill_in(with: "third description")
    click_button "Save"

    rendered_descriptions = all(".attribute.description")
    expect(rendered_descriptions.count).to eq 3
    expect(rendered_descriptions.map(&:text)).to eq ["test description", "another description", "third description"]
  end
end
