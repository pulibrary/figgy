# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Order Manager", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set) }
  let(:resource) do
    res = FactoryBot.create_for_repository(:scanned_resource)
    res.member_ids = [file_set.id]
    adapter.persister.save(resource: res)
  end

  before do
    sign_in user
  end

  scenario "users visit the order manager interface" do
    visit polymorphic_path [:order_manager, resource]
    expect(page).to have_css ".lux-orderManager"
  end
end
