# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Reports" do
  let(:user) { FactoryBot.create(:admin) }
  before do
    sign_in user
  end

  describe "Collection Item and Image Count Report" do
    it "renders a parameter input page", js: true do
      visit "/reports/collection_item_and_image_count"
      expect(page).to have_content("Collection Item and Image Count Report")
      expect(page).to have_selector("input#collection_ids")
      expect(page).to have_selector("input#date_range")
    end
  end
end
