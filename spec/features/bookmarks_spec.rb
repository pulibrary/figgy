# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bookmarks" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:title) { "Fear and Trembling" }
  let(:persister) { adapter.persister }

  before do
    persister.save(resource: FactoryBot.build(:scanned_resource, title: title))
  end

  describe "navigating from the homepage" do
    it "has a link to the history page" do
      sign_in user
      visit bookmarks_path
      expect(page).to have_content "You have no bookmarks"
    end
  end

  it "add and remove bookmarks from search results" do
    sign_in user
    visit root_path
    fill_in id: "catalog_search", with: "Fear"
    click_button id: "keyword-search-submit"
    click_button "Bookmark"
    expect(page).to have_content "Successfully added bookmark."

    fill_in "q", with: "Fear"
    click_button id: "keyword-search-submit"
    click_button "Remove bookmark"
    expect(page).to have_content "Successfully removed bookmark."
  end

  it "adds and delete bookmarks from the show page" do
    sign_in user
    visit root_path
    fill_in id: "catalog_search", with: "Fear"
    click_button id: "keyword-search-submit"
    click_button "Bookmark"
    click_button "Remove bookmark"
    expect(page).to have_content "Successfully removed bookmark."
  end
end
