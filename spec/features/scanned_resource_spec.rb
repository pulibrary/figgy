# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Scanned Resource" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_ezid(shoulder: "99999/fk4", blade: "123456")

    sign_in user
  end

  scenario "creating a new resource", js: true do
    visit new_scanned_resource_path

    fill_in "Title", with: "Test Title"
    # fill_in
    click_button "Save"

    expect(page).to have_content "Embargo Date"
  end
end
