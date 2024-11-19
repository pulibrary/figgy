# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Scanned Map" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_ezid
    sign_in user
  end

  scenario "edit page has a button that can clear form-entered bounding boxes", js: true do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    coverage = GeoCoverage.new(43.039, -69.856, 42.943, -71.032)
    resource = FactoryBot.create_for_repository(:scanned_map, coverage: coverage.to_s, files: [file])

    visit solr_document_path(id: resource.id)
    expect(page).to have_selector('div#bbox[data-coverage="northlimit=43.039; eastlimit=-69.856; southlimit=42.943; westlimit=-71.032; units=degrees; projection=EPSG:4326"]')

    visit edit_scanned_map_path(id: resource.id)
    click_button("Clear Coverage")
    click_button("Save")
    expect(page).to have_selector('div#bbox[data-coverage=""]')
  end
end
