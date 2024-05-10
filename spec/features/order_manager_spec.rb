# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Order Manager", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:file_set1) { FactoryBot.create_for_repository(:file_set) }
  let(:file_set2) { FactoryBot.create_for_repository(:file_set) }
  let(:resource) do
    res = FactoryBot.create_for_repository(:scanned_resource)
    res.member_ids = [file_set1.id, file_set2.id]
    adapter.persister.save(resource: res)
  end

  before do
    sign_in user
  end

  scenario "users visit the order manager interface" do
    visit polymorphic_path [:order_manager, resource]
    expect(page).to have_css ".lux-orderManager"

    # test for selecting a single resource member card
    expect(page).not_to have_css ".lux-card-selected"
    page.all(".lux-card")[0].click
    expect(page).to have_css(".lux-card-selected", text: "File Set 1")

    # test for updating member label
    find_field('itemLabel', with: 'File Set 1').set('Page 1')
    expect(page).to have_css(".lux-card > p", text: "Page 1")

    # test selecting multiple members
    expect(page).not_to have_css(".lux-card-selected", text: "File Set 2")
    find("button.lux-dropdown-button", text: "Selection Options").click
    find("button.lux-menu-item", text: "All").click
    expect(page).to have_css(".lux-card-selected", text: "Page 1")
    expect(page).to have_css(".lux-card-selected", text: "File Set 2")

    # test generating labels

    # test reorder of members via cut and paste

    # test the deep zoom functionality

    # test that setting page type, start page, and resource thumbnail and saving will retain changes

  end
end
