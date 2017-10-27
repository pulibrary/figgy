# frozen_string_literal: true
require 'rails_helper'

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

    context 'while editing existing folders' do
      scenario 'users can delete existing folders' do
        visit polymorphic_path [:edit, ephemera_folder]

        page.accept_confirm do
          click_link "Delete This Ephemera Folder"
        end

        expect(page.find(:css, ".alert-info")).to have_content "Deleted EphemeraFolder"
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
