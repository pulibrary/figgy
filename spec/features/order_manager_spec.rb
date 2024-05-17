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

    # test generating labels for multiple members
    find_field('unitLabel').set('p.')
    find_field('startNum').set('10')
    # capybara throws error on all of these approaches
    # -- this is likely because the lux-input-checkbox hides the default checkbox and restyles it
    # -- checking this box reveals the bracketLocation select input which also cannot be tested with capybara
    # check "#addBrackets"
    # find("#addBrackets").set(true)
    # find("#addBrackets").check

    expect(page).to have_css(".lux-card-selected", text: "p.10")
    expect(page).to have_css(".lux-card-selected", text: "p.11")
    find("#labelMethod option[value='foliate']").select_option
    expect(page).to have_css(".lux-card-selected", text: "f. 10r.")
    expect(page).to have_css(".lux-card-selected", text: "f. 10v.")
    find("#twoUp option[value='true']").select_option
    expect(page).to have_css(".lux-card-selected", text: "f. 10r./10v.")
    expect(page).to have_css(".lux-card-selected", text: "f. 11r./11v.")
    find_field('twoUpSeparator', with: '/').set('-')
    expect(page).to have_css(".lux-card-selected", text: "f. 10r.-10v.")
    expect(page).to have_css(".lux-card-selected", text: "f. 11r.-11v.")
    find_field('frontLabel', with: 'r.').set('(recto)')
    find_field('backLabel', with: 'v.').set('(verso)')
    expect(page).to have_css(".lux-card-selected", text: "f. 10(recto)-10(verso)")
    expect(page).to have_css(".lux-card-selected", text: "f. 11(recto)-11(verso)")
    # note: startWith has been broken before the vue3 upgrade
    # see: https://github.com/pulibrary/figgy/issues/6400
    # find("#startWith option[value='back']").select_option
    # expect(page).to have_css(".lux-card-selected", text: "f. 10(verso)-10(recto)")
    # expect(page).to have_css(".lux-card-selected", text: "f. 11(verso)-11(recto)")

    # test reorder of members via cut and paste
    page.all(".lux-card")[0].click
    find("button.lux-dropdown-button", text: "With Selected...").click
    find("button.lux-menu-item", text: "Cut").click
    page.all(".lux-card").last.click
    find("button.lux-dropdown-button", text: "With Selected...").click
    find("button.lux-menu-item", text: "Paste After").click
    first = page.all(".lux-card")[0]
    last = page.all(".lux-card").last
    expect(first.has_text? ("f. 11(recto)-11(verso)")).to be(true)
    expect(last.has_text? ("f. 10(recto)-10(verso)")).to be(true)
    expect(page).to have_css(".lux-alert-info > span", text: "Page order has changed.")


    # test the deep zoom functionality
    page.all(".lux-card")[0].click
    viewer = page.all("#viewer")[0]
    expect(viewer.has_element? ("canvas")).to be(true)

    # test that saving will provide a success notice and preserve changes
    expect(page).not_to have_css(".lux-alert", text: "Your work has been saved!")
    page.all("#save_btn")[0].click
    expect(page).to have_css(".lux-alert", text: "Your work has been saved!")
    refresh
    first = page.all(".lux-card")[0]
    expect(first.has_text? ("f. 11(recto)-11(verso)")).to be(true)
  end
end
