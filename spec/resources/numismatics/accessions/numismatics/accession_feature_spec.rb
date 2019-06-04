# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Numismatics::Accessions" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  scenario "creating a new resource" do
    visit new_numismatics_accession_path

    expect(page).to have_field "Account"
    expect(page).to have_field "Cost"
    expect(page).to have_field "Date"
    expect(page).to have_field "Firm"
    expect(page).to have_field "Note"
    expect(page).to have_field "Number"
    expect(page).to have_field "Number of items"
    expect(page).to have_field "Numismatic Reference"
    expect(page).to have_field "Part"
    expect(page).to have_field "Person"
    expect(page).to have_field "Private note"
    expect(page).to have_field "Type"

    fill_in "Type", with: "purchase"
    click_button "Save"

    expect(page).to have_content "purchase"
  end
end
