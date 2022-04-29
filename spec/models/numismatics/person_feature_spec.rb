# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Numismatic People" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  scenario "creating a new resource" do
    visit new_numismatics_person_path

    expect(page).to have_field "Name1"
    expect(page).to have_field "Name2"
    expect(page).to have_field "Epithet"
    expect(page).to have_field "Family"
    expect(page).to have_field "Born"
    expect(page).to have_field "Died"
    expect(page).to have_field "Class of"
    expect(page).to have_field "Years active start"
    expect(page).to have_field "Years active end"

    fill_in "Name1", with: "Hadrian"
    click_button "Save"

    expect(page).to have_content "Hadrian"
  end
end
