# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Refresh", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  before do
    sign_in user
  end

  context "collection with members" do
    it "selects the sort_by field and sort members", js: true do
      collection = persister.save(resource: FactoryBot.build(:collection))
      persister.save(resource: FactoryBot.build(:scanned_resource, member_of_collection_ids: [collection.id]))

      visit "catalog/#{collection.id}"
      expect(page).to have_link "Edit This Collection", href: edit_collection_path(collection)
      expect(page).to have_link "Delete This Collection", href: collection_path(collection)
      expect(page).not_to have_link "File Manager"
      expect(page).to have_css ".per_page"
      expect(page).to have_button "Refresh"
      expect(page).to have_xpath("//select[@id='sort']/option[1]", visible: :all)
      filter_value = page.find("#sort", visible: :false).value
      filter_param = Rack::Utils.parse_nested_query(filter_value).to_param[0...-1]
      click_on "Refresh"
      expect(current_url).to include "/catalog/#{collection.id}?utf8=%E2%9C%93&sort=#{filter_param}&per_page="
      expect(page).not_to have_text("Sorry, I don't understand your search.")
    end
  end
end
