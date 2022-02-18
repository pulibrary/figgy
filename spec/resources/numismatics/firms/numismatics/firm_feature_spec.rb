# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Numismatics::Firms" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  scenario "creating a new resource" do
    visit new_numismatics_firm_path

    expect(page).to have_field "City"
    expect(page).to have_field "Name"

    fill_in "City", with: "New Orleans"
    click_button "Save"

    expect(page).to have_content "New Orleans"
  end
end
