# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Ephemera Boxes" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end
  let(:ephemera_box) do
    res = FactoryBot.create_for_repository(:ephemera_box)
    adapter.persister.save(resource: res)
  end
  let(:ephemera_project) do
    res = FactoryBot.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id])
    adapter.persister.save(resource: res)
  end

  before do
    sign_in user
    ephemera_project
  end

  context "when an ephemera box has been persisted with invalid data" do
    let(:change_set) do
      EphemeraBoxChangeSet.new(ephemera_box)
    end

    before do
      change_set.barcode = "1234"
      change_set_persister.save(change_set: change_set)
    end

    scenario "users see validation errors" do
      visit polymorphic_path [:edit, ephemera_box]
      expect(page).to have_content "has an invalid checkdigit"
    end
  end

  context "when a user creates a new ephemera box" do
    context "with ephemera boxes already created" do
      scenario "users see a warning if they try to use duplicate barcodes", js: true do
        visit ephemera_project_add_box_path(parent_id: ephemera_project.id)
        page.fill_in "ephemera_box_barcode", with: "00000000000000"
        page.fill_in "ephemera_box_box_number", with: "1"
        expect(page).to have_content "This barcode is already in use"

        visit ephemera_project_add_box_path(parent_id: ephemera_project.id)
        page.fill_in "ephemera_box_barcode", with: "33333333333333"
        page.fill_in "ephemera_box_box_number", with: "2"
        expect(page).not_to have_content "This barcode is already in use"
      end
    end
  end

  context "when a user edits an existing ephemera box" do
    context "with ephemera boxes already created" do
      let(:existing_ephemera_box) do
        res = FactoryBot.create_for_repository(:ephemera_box)
        adapter.persister.save(resource: res)
      end
      let(:change_set) do
        EphemeraBoxChangeSet.new(existing_ephemera_box)
      end
      let(:change_set_persister) do
        ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
      end

      before do
        change_set.barcode = "11111111111110"
        change_set_persister.save(change_set: change_set)
      end

      scenario "users see a warning if they try to use duplicate barcodes", js: true do
        visit polymorphic_path [:edit, ephemera_box]
        expect(page).to have_field "Barcode"
        page.fill_in "ephemera_box_barcode", with: "33333333333333"
        page.fill_in "ephemera_box_box_number", with: "3"
        expect(page).not_to have_content "This barcode is already in use"

        page.fill_in "ephemera_box_barcode", with: ""
        page.fill_in "ephemera_box_barcode", with: "11111111111110"
        page.fill_in "ephemera_box_box_number", with: "1"
        expect(page).to have_content "This barcode is already in use"
      end
    end
  end

  describe "viewing a box" do
    # make another box with a folder in it so we can confirm these don't show
    # up in filtered results
    let(:ephemera_folder) do
      FactoryBot.create_for_repository(:ephemera_folder)
    end
    let(:ephemera_folder2) do
      FactoryBot.create_for_repository(:ephemera_folder)
    end
    let(:ephemera_box) do
      FactoryBot.create_for_repository(:ephemera_box, member_ids: [ephemera_folder.id])
    end
    let(:ephemera_box2) do
      FactoryBot.create_for_repository(:ephemera_box, member_ids: [ephemera_folder2.id])
    end
    let(:ephemera_project) do
      FactoryBot.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id, ephemera_box2.id])
    end

    it "links to a search result limited to folders in that specific box" do
      # These don't get properly indexed until they're saved, and the project
      # has to exist first
      change_set_persister.save(change_set: ChangeSet.for(ephemera_folder))
      change_set_persister.save(change_set: ChangeSet.for(ephemera_folder2))
      change_set_persister.save(change_set: ChangeSet.for(ephemera_box))
      change_set_persister.save(change_set: ChangeSet.for(ephemera_box2))

      visit "/catalog/#{ephemera_box.id}"

      page.click_link("View all 1 items in this box")

      expect(page).to have_selector("span.constraint-value", text: "Ephemera Project Test Project")
      expect(page).to have_selector("span.constraint-value", text: "Ephemera Box #{ephemera_box.id}")
      expect(page).to have_selector("h3.document-title-heading", count: 1)
    end
  end
end
