# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.feature "Ephemera Folders", js: true do
  let(:user) { FactoryGirl.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:ephemera_project) do
    res = FactoryGirl.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id])
    adapter.persister.save(resource: res)
  end
  let(:ephemera_box) do
    res = FactoryGirl.create_for_repository(:ephemera_box, member_ids: [ephemera_folder.id])
    adapter.persister.save(resource: res)
  end
  let(:ephemera_folder) do
    res = FactoryGirl.create_for_repository(:ephemera_folder)
    adapter.persister.save(resource: res)
  end

  before do
    sign_in user
    ephemera_project
    ephemera_box
    ephemera_folder
  end

  context 'within an existing ephemera project' do
    scenario 'users can save a new folder' do
      visit boxless_new_ephemera_folder_path(parent_id: ephemera_project.id)

      page.fill_in 'ephemera_folder_barcode', with: '00000000000000'
      page.fill_in 'ephemera_folder_folder_number', with: '1'
      page.fill_in 'ephemera_folder_title', with: 'test new ephemera folder'
      page.fill_in 'ephemera_folder_language', with: 'test language'
      page.fill_in 'ephemera_folder_genre', with: 'test genre'
      page.fill_in 'ephemera_folder_width', with: 'test width'
      page.fill_in 'ephemera_folder_height', with: 'test height'
      page.fill_in 'ephemera_folder_page_count', with: 'test page count'
      page.find(:css, '[data-id="ephemera_folder_rights_statement"]').click
      page.all(:css, '.dropdown-menu.open').first.all(:css, 'a:last-child').last.click

      page.click_on 'Save'

      expect(page).to have_content 'test new ephemera folder'
      expect(page).to have_content 'Attributes'
      expect(page).to have_content 'EphemeraFolder'
    end

    scenario 'users can save a new folder and create another' do
      visit boxless_new_ephemera_folder_path(parent_id: ephemera_project.id)

      page.fill_in 'ephemera_folder_barcode', with: '00000000000000'
      page.fill_in 'ephemera_folder_folder_number', with: '2'
      page.fill_in 'ephemera_folder_title', with: 'test new ephemera folder'
      page.fill_in 'ephemera_folder_language', with: 'test language'
      page.fill_in 'ephemera_folder_genre', with: 'test genre'
      page.fill_in 'ephemera_folder_width', with: 'test width'
      page.fill_in 'ephemera_folder_height', with: 'test height'
      page.fill_in 'ephemera_folder_page_count', with: 'test page count'
      page.find(:css, '[data-id="ephemera_folder_rights_statement"]').click
      page.all(:css, '.dropdown-menu.open').first.all(:css, 'a:last-child').last.click

      page.click_on 'Save and Create Another'

      expect(page).to have_content 'Folder 2 Saved, Creating Another...'
    end
  end

  context 'within an existing ephemera box' do
    scenario 'users can save a new folder' do
      visit parent_new_ephemera_box_path(parent_id: ephemera_box.id)

      page.fill_in 'ephemera_folder_barcode', with: '00000000000000'
      page.fill_in 'ephemera_folder_folder_number', with: '3'
      page.fill_in 'ephemera_folder_title', with: 'test new ephemera folder'
      page.fill_in 'ephemera_folder_language', with: 'test language'
      page.fill_in 'ephemera_folder_genre', with: 'test genre'
      page.fill_in 'ephemera_folder_width', with: 'test width'
      page.fill_in 'ephemera_folder_height', with: 'test height'
      page.fill_in 'ephemera_folder_page_count', with: 'test page count'
      page.find(:css, '[data-id="ephemera_folder_rights_statement"]').click
      page.all(:css, '.dropdown-menu.open').first.all(:css, 'a:last-child').last.click

      page.click_on 'Save'

      expect(page).to have_content 'test new ephemera folder'
      expect(page).to have_content 'Attributes'
      expect(page).to have_content 'EphemeraFolder'
    end

    scenario 'users see a warning if they try to use duplicate barcodes' do
      visit parent_new_ephemera_box_path(parent_id: ephemera_box.id)
      page.fill_in 'ephemera_folder_barcode', with: '00000000000000'
      page.fill_in 'ephemera_folder_folder_number', with: '1'
      expect(page).to have_content 'This barcode is already in use'

      page.fill_in 'ephemera_folder_barcode', with: '11111111111111'
      page.fill_in 'ephemera_folder_folder_number', with: '2'
      expect(page).not_to have_content 'This barcode is already in use'
    end

    scenario 'users can save a new folder and create another' do
      visit parent_new_ephemera_box_path(parent_id: ephemera_box.id)

      page.fill_in 'ephemera_folder_barcode', with: '00000000000000'
      page.fill_in 'ephemera_folder_folder_number', with: '4'
      page.fill_in 'ephemera_folder_title', with: 'test new ephemera folder'
      page.fill_in 'ephemera_folder_language', with: 'test language'
      page.fill_in 'ephemera_folder_genre', with: 'test genre'
      page.fill_in 'ephemera_folder_width', with: 'test width'
      page.fill_in 'ephemera_folder_height', with: 'test height'
      page.fill_in 'ephemera_folder_page_count', with: 'test page count'
      page.find(:css, '[data-id="ephemera_folder_rights_statement"]').click
      page.all(:css, '.dropdown-menu.open').first.all(:css, 'a:last-child').last.click

      page.click_on 'Save and Create Another'

      expect(page).to have_content 'Folder 4 Saved, Creating Another...'
    end
  end

  context 'when users have added an ephemera folder' do
    scenario 'users can view an existing folder' do
      visit Valhalla::ContextualPath.new(child: ephemera_folder).show
      expect(page).to have_content 'test folder'
    end

    scenario 'users can edit existing folders' do
      visit polymorphic_path [:edit, ephemera_folder]
      page.fill_in 'ephemera_folder_title', with: 'updated folder title'
      page.find('form.edit_ephemera_folder').native.submit

      expect(page).to have_content 'updated folder title'
    end

    context 'when users are managing files' do
      let(:file1) { fixture_file_upload('files/example.tif', 'image/tiff') }
      let(:file2) { fixture_file_upload('files/color-landscape.tif', 'image/tiff') }
      let(:ephemera_folder) do
        res = FactoryGirl.create_for_repository(:ephemera_folder, files: [file1, file2])
        adapter.persister.save(resource: res)
      end

      xscenario 'users can edit file order for the manifest', sort_folders: true do
        visit file_manager_ephemera_folder_path(id: ephemera_folder.id)
        expect(page).to have_css '#sortable li', count: 2

        find(:css, "#sortable li:first-child input.title").set('2')
        find(:css, "#sortable li:last-child input.title").set('1')

        click_button 'Sort alphabetically'
        click_button 'Save'

        expect(find(:css, "#sortable li:first-child input.title").value).to eq '1'
        expect(find(:css, "#sortable li:last-child input.title").value).to eq '2'
      end
    end

    context 'while editing existing folders' do
      scenario 'users can delete existing folders' do
        visit polymorphic_path [:edit, ephemera_folder]

        page.accept_confirm do
          click_link "Delete This Ephemera Folder"
        end

        expect(page.find(:css, ".alert-info")).to have_content "Deleted EphemeraFolder"
      end

      scenario 'users see a warning if they try to use duplicate barcodes' do
        visit polymorphic_path [:edit, ephemera_folder]
        page.fill_in 'ephemera_folder_barcode', with: '00000000000000'
        page.fill_in 'ephemera_folder_folder_number', with: '1'
        expect(page).to have_content 'This barcode is already in use'

        page.fill_in 'ephemera_folder_barcode', with: '11111111111110'
        page.fill_in 'ephemera_folder_folder_number', with: '2'
        expect(page).not_to have_content 'This barcode is already in use'
      end
    end

    scenario 'users can delete existing folders' do
      visit Valhalla::ContextualPath.new(child: ephemera_folder).show

      page.accept_confirm do
        click_link "Delete This Ephemera Folder"
      end

      expect(page.find(:css, ".alert-info")).to have_content "Deleted EphemeraFolder"
    end
  end
end
