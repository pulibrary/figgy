# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Ephemera Vocabularies" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:ephemera_project) do
    res = FactoryBot.create_for_repository(:ephemera_project)
    adapter.persister.save(resource: res)
  end

  before do
    sign_in user
  end

  context "when users visit a project" do
    let(:ephemera_vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary) }

    before do
      adapter.persister.save(resource: ephemera_vocabulary)
    end

    scenario "users can add fields linked to controlled vocabularies" do
      visit ContextualPath.new(child: ephemera_project).show
      click_link "Add Field"

      page.select "EphemeraFolder.subject", from: "Name"
      page.select ephemera_vocabulary.label.first, from: "Vocabulary"
      page.click_button "Save"

      visit ContextualPath.new(child: ephemera_project).show

      expect(page).to have_content "EphemeraFolder.subject"
    end

    context "when users have added a field and a box" do
      let(:ephemera_field) do
        res = FactoryBot.create_for_repository(:ephemera_field, member_of_vocabulary_id: ephemera_vocabulary.id)
        adapter.persister.save(resource: res)
      end

      let(:ephemera_box) do
        res = FactoryBot.create_for_repository(:ephemera_box)
        adapter.persister.save(resource: res)
      end

      let(:ephemera_term) do
        res = FactoryBot.create_for_repository(:ephemera_term)
        res.member_of_vocabulary_id = ephemera_vocabulary.id
        adapter.persister.save(resource: res)
      end

      before do
        ephemera_term

        ephemera_project.member_ids = [ephemera_box.id, ephemera_field.id]
        adapter.persister.save(resource: ephemera_project)
      end

      scenario "users can add folder metadata using controlled vocabularies" do
        visit parent_new_ephemera_box_path(parent_id: ephemera_box.id)

        expect(page).to have_select "Language", with_options: ["test term"]
      end

      # Leaving this one as JS true just to ensure that the dropdown JS works.
      scenario "users can edit folder metadata with controlled vocabularies", js: true do
        folder = FactoryBot.create_for_repository(:ephemera_folder, language: ephemera_term.id)
        adapter.persister.save(resource: folder)

        ephemera_box.member_ids = [folder.id]
        adapter.persister.save(resource: ephemera_box)

        visit edit_ephemera_folder_path(folder.id)
        expect(page).to have_selector(".ephemera_folder_language button.dropdown-toggle")
        page.find(:css, '[data-id="ephemera_folder_language"]').click
        expect(page.all(:css, ".dropdown-menu.open").first.all(:css, "a:last-child").last).to have_content "test term"
      end
    end

    context "when users have added a field and boxless" do
      let(:ephemera_field) do
        res = FactoryBot.create_for_repository(:ephemera_field, member_of_vocabulary_id: ephemera_vocabulary.id)
        adapter.persister.save(resource: res)
      end

      before do
        res = FactoryBot.create_for_repository(:ephemera_term)
        res.member_of_vocabulary_id = ephemera_vocabulary.id
        adapter.persister.save(resource: res)

        ephemera_project.member_ids = [ephemera_field.id]
        adapter.persister.save(resource: ephemera_project)
      end

      scenario "users can add folder metadata using controlled vocabularies" do
        visit boxless_new_ephemera_folder_path(parent_id: ephemera_project.id)

        expect(page).to have_select "Language", with_options: ["test term"]
      end
    end
  end

  scenario "users can create controlled vocabularies" do
    visit new_ephemera_vocabulary_path

    expect(page).to have_selector("h1", text: "New Vocabulary")
    page.fill_in "ephemera_vocabulary_label", with: "test creating a vocabulary"
    page.click_button "Save"

    expect(page).to have_content "test creating a vocabulary"
  end

  context "when users have added a controlled vocabulary" do
    let(:ephemera_vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary) }

    before do
      adapter.persister.save(resource: ephemera_vocabulary)
    end

    scenario "users can view existing controlled vocabularies" do
      visit ContextualPath.new(child: ephemera_vocabulary).show

      expect(page).to have_content "test vocabulary"
    end

    scenario "users can view all existing controlled vocabularies" do
      visit ephemera_vocabularies_path

      expect(page.find(:css, "td.vocab:first-child")).to have_content "test vocabulary"
    end

    scenario "users can edit controlled vocabularies" do
      visit polymorphic_path [:edit, ephemera_vocabulary]

      page.fill_in "ephemera_vocabulary_label", with: "updated label"
      page.click_button "Save"

      visit polymorphic_path [:edit, ephemera_vocabulary]

      expect(page).to have_content "updated label"
    end

    scenario "users can delete controlled vocabularies" do
      visit ContextualPath.new(child: ephemera_vocabulary).show

      click_link "Delete This Ephemera Vocabulary"

      expect(page.find(:css, ".alert-info")).to have_content "Deleted EphemeraVocabulary"
    end

    scenario "users can add categories to controlled vocabularies" do
      visit ContextualPath.new(child: ephemera_vocabulary).show
      click_link "Add Category"

      expect(page).to have_selector("h1", text: "New Category")
      page.fill_in "ephemera_vocabulary_label", with: "test category"
      page.click_button "Save"

      expect(page).to have_content "test category"
      visit ContextualPath.new(child: ephemera_vocabulary).show
      expect(page).to have_content "test category"
    end

    scenario "users can add terms to controlled vocabularies" do
      visit ContextualPath.new(child: ephemera_vocabulary).show
      click_link "Add Term"

      page.fill_in "ephemera_term_label", with: "test term"
      page.click_button "Save"

      expect(page).to have_content "test term"
      visit ContextualPath.new(child: ephemera_vocabulary).show
      expect(page).to have_content "test term"
    end
  end
end
