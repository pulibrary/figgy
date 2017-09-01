# frozen_string_literal: true
require 'rails_helper'

RSpec.feature "Home Page", js: true do
  let(:user) { FactoryGirl.create(:admin) }
  before do
    sign_in user
  end

  scenario "displays creation links for administrators" do
    click_link 'Add'
    expect(page).to have_link "New Scanned Resource"
    expect(page).to have_link "Add a Collection", href: "/collections/new"
    expect(page).to have_link "Manage Roles"
  end
end
