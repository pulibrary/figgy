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
    fill_in "Embargo Date", with: "1/14/2025"
    # I'm not sure why we need visible: all but we seem to
    notice_type_form_field = find_by_id("scanned_resource_notice_type", visible: "all")
    notice_options = notice_type_form_field.find_all("option")
    expect(notice_options.map(&:text)).to eq ["Harmful Content", "Explicit Content", "Senior Thesis"]
#     within notice_type_form_field do
#       select "Senior Thesis"
#     end
    click_button "Save"
    expect(page).to have_content "Embargo Date"
    # expect(page).to have_content "Senior Thesis"
  end
end
