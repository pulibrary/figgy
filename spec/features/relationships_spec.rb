# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Related Resources", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }

  before do
    sign_in user
  end

  context "on a scanned resource parent show page" do
    it "can attach and detach a member" do
      parent = persister.save(resource: FactoryBot.create_for_repository(:scanned_resource))
      child = persister.save(resource: FactoryBot.create_for_repository(:scanned_resource))

      # attach
      visit "/catalog/#{parent.id}"
      fill_in("scanned_resource[member_ids]", with: child.id.to_s)
      click_on("button")

      # wait for the new row to load so we get through the controller before we
      # look for the new object
      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [child.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end
  end
end
