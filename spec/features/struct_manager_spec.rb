# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Structure Manager", js: true do
  with_queue_adapter :inline
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource) do
    FactoryBot.create_for_repository(:scanned_resource, files: [file, file2])
  end

  before do
    sign_in user
  end

  scenario "users visit the structure manager interface" do
    visit polymorphic_path [:structure, resource]
    expect(page).to have_css ".lux-structManager"

    # test select root node
    find(".folder-container > div:first-child").click
    expect(page).to have_css ".folder-container.selected"

    # test create new folder
    find("button.lux-dropdown-button").click
    find("button.lux-menu-item", text: "Create New Folder (Ctrl-/)").click
    expect(page).to have_css("div.folder-label", text: "Untitled")

    # test edit folder label
    page.all("button.toggle-edit")[1].click
    expect(page).to have_css "input.folder-label-input"
    find("input.folder-label-input").set("Chapter Foo")
    find("button.save-label").click
    expect(page).to have_css("div.folder-label", text: "Chapter Foo")

    # test cut of gallery item
    expect(page).not_to have_css ".lux-card-disabled"
    find(".lux-card", match: :first).click
    find("button.lux-dropdown-button").click
    find("button.lux-menu-item", text: "Cut (Ctrl-x)").click
    expect(page).to have_css ".lux-card-disabled"

    # test paste of gallery item into a tree structure folder
    # the hotkey for paste is a period (.) to avoid hotkey collisions with Windows Ctrl-V
    find("div.folder-label", text: "Chapter Foo").click
    find("button.lux-dropdown-button").click
    find("button.lux-menu-item", text: "Paste (Ctrl-.)").click
    expect(page).to have_css ".lux-structManager .file"

    # test create new folder with ctrl-/
    find("div.folder-label", match: :first).click
    expect(page).not_to have_css("div.folder-label", text: "Untitled")
    page.send_keys [:control, "/"]
    expect(page).to have_css("div.folder-label", text: "Untitled")

    # test cutting a folder using keyboard commands
    first_node = find("ul.lux-tree-sub", match: :first)
    expect(first_node).to have_css(".folder-label", text: "Chapter Foo")
    find("div.folder-label", text: "Chapter Foo").click
    page.send_keys [:control, "x"]
    expect(page).to have_selector(".folder-container.disabled", count: 2)

    # test paste of a cut folder into another folder using keyboard commands
    find("div.folder-label", text: "Untitled").click
    page.send_keys [:control, "."]
    first_node = find("ul.lux-tree-sub", match: :first)
    expect(first_node).to have_css(".folder-label", text: "Untitled")

    # test zoom on item in gallery
    expect(page).not_to have_css ".lux-modal"
    find(".lux-gallery button.zoom-icon", match: :first).click
    expect(page).to have_css ".lux-modal"
    find("button.close-zoom").click
    expect(page).not_to have_css ".lux-modal"

    # test zoom on item in tree
    find(".lux-tree button.zoom-file", match: :first).click
    expect(page).to have_css ".lux-modal"
    page.send_keys [:escape]
    expect(page).not_to have_css ".lux-modal"

    # test select all nodes by clicking on the root
    find(".folder-container > div:first-child", match: :first).click
    expect(page).to have_selector(".folder-container.selected", count: 4)

    # test expand and collapse of the tree
    find("button.expand-collapse", match: :first).click
    expect(page).not_to have_selector(".lux-tree-sub")
    find("button.expand-collapse", match: :first).click
    expect(page).to have_selector(".lux-tree-sub", visible: true)

    # test delete folder with subfolders/items
    expect(page).to have_selector(".lux-card", count: 1)
    accept_confirm do
      find("ul.lux-tree-sub button.delete-folder", match: :first).click
    end
    expect(page).to have_selector(".lux-card", count: 2)

    # test create folder with button click
    expect(page).not_to have_css(".folder-label", text: "Untitled")
    find(".lux-tree button.create-folder").click
    expect(page).to have_css(".folder-label", text: "Untitled")

    # test paste group of selected gallery items into new folder
    find(".lux-card", match: :first).click
    all(".lux-card").last.click(:shift)
    expect(page).to have_selector(".lux-card-selected", count: 2)
    page.send_keys [:control, "g"]
    expect(page).to have_selector(".lux-card", count: 0)
    expect(page).to have_selector(".lux-structManager .file", count: 2)
  end
end
