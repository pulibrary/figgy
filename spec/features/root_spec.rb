# frozen_string_literal: true
require 'rails_helper'

RSpec.feature "Home Page", js: true do
  let(:user) { FactoryBot.create(:admin) }
  before do
    FactoryBot.create_for_repository(:ephemera_project)
    sign_in user
  end

  scenario "displays creation links for administrators" do
    click_link 'Add'
    expect(page).to have_link "New Scanned Resource"
    expect(page).to have_link "New Media Resource"
    expect(page).to have_link "Add a Collection", href: "/collections/new"
    expect(page).to have_link "Manage Roles"
    expect(page).to have_content "Test Project"
    expect(page).to have_link "View Boxes"
    expect(page).to have_link "Add Box"
    expect(page).to have_link "New Simple Resource"
  end
end
