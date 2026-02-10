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
    query_service = adapter.query_service
    r = query_service.find_by(id: resource.id)
    fileset = query_service.find_by(id: r.member_ids.last)
    fileset_changeset = ChangeSet.for(fileset)
    fileset_changeset.validate(title: "example2.tif")
    ChangeSetPersister.default.save(change_set: fileset_changeset)
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
    # clicking this dropdown is arbitrary click just to remove focus from the folder label
    find("button.lux-dropdown-button").click
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

    # test collapse of a tree node
    find("button.expand-collapse", match: :first).click
    expect(page).not_to have_selector(".lux-tree-sub")

    # test that selecting does not expand/collapse
    find(".folder-container > div:first-child").click
    expect(page).not_to have_selector(".lux-tree-sub", visible: true)

    # test expand of a tree node
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

    # test that new folders are placed at top, not the bottom of the parent folder
    page.all("button.toggle-edit")[1].click
    find("input.folder-label-input", match: :first).set("MyFolder")
    page.send_keys [:enter]
    page.all("button.create-folder")[0].click
    expect(page.all(".lux-structManager .folder-container")[1]).to have_text("Untitled")
    # TODO: do this for pasted folders as well
    page.all(".lux-structManager .folder-container")[2].click
    page.send_keys [:control, "x"]
    page.all("button.create-folder")[0].click
    page.send_keys [:control, "."]
    expect(page.all(".lux-structManager .folder-container")[1]).to have_text("MyFolder")

    # test paste group of selected gallery items into new folder
    find(".lux-card", match: :first).click
    all(".lux-card").last.click(:shift)
    expect(page).to have_selector(".lux-card-selected", count: 2)
    page.send_keys [:control, "g"]
    expect(page).to have_selector(".lux-card", count: 0)
    expect(page).to have_selector(".lux-structManager .file", count: 2)

    # test moving folders up and down to reorder them
    page.all("button.toggle-edit")[1].click
    expect(page).to have_css "input.folder-label-input"
    # label it so we can distinguish between the two sub-folders
    # and use \n to simulate "enter"
    find("input.folder-label-input").set("First\n")
    page.all(".lux-structManager .folder-container")[1].click
    expect(page.all(".lux-structManager .folder-container")[1]).to have_text("First")
    page.send_keys [:control, :shift, :arrow_down]
    expect(page.all(".lux-structManager .folder-container")[1]).not_to have_text("First")
    page.send_keys [:control, :shift, :arrow_up]
    expect(page.all(".lux-structManager .folder-container")[1]).to have_text("First")

    # test to make sure that file labels cannot be edited
    expect(page).not_to have_selector(".file-edit.toggle-edit")

    # test to make sure that file items cannot be reordered
    # note: example2.tif is the first hit because it has been reordered through the
    test_file = find(".file-label", match: :first)
    test_file.click
    expect(test_file).to have_text("example2.tif")
    page.send_keys [:control, :shift, :arrow_down]
    test_file2 = find(".file-label", match: :first)
    expect(test_file2).to have_text("example2.tif")

    # TODO: write a test to make sure that if a file is the next item in the folder array, after a selected folder,
    # then MoveDown is does not change the item's position.
    # (Example DnD implementation with VueDraggable: https://codepen.io/naffarn/pen/KKdVRRE)
  end
end
