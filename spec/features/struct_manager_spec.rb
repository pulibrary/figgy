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
    find(".folder-container > div:first-child").click
    expect(page).to have_css ".folder-container.selected"
    find("button.lux-dropdown-button").click
    find("button.lux-menu-item", :text=> "Create New Folder (Ctrl-n)").click
    expect(page).to have_css("div.folder-label", text: "Untitled")

    #test keyboard shortcuts
    #page.native.send_keys :control, :shift, 'n'
    # expect(page).to have_text "Untitled"
    # binding.pry
  end

end
