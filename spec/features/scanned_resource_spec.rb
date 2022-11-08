# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Scanned Resource" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_ezid(shoulder: "99999/fk4", blade: "123456")

    sign_in user
  end

  scenario "creating a new resource", js: true do
    visit new_scanned_resource_path

    fill_in "Title", with: "Test Title"
    fill_in "Embargo Date", with: "1/14/2025"
    # I'm not sure why we need visible: all but we seem to
    notice_type_form_field = find_by_id("scanned_resource_notice_type", visible: "all")
    notice_options = notice_type_form_field.find_all("option")
    expect(notice_options.map(&:text)).to eq ["", "Harmful Content", "Explicit Content", "Senior Thesis"]
    within notice_type_form_field do
      select "Senior Thesis"
    end
    click_button "Save"
    expect(page).to have_content "Embargo Date"
    expect(page).to have_content "Senior Thesis"
  end

  scenario "show page has a viewer", js: true do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])

    visit solr_document_path(id: resource.id)

    within_frame(find(".uv-container > iframe")) do
      expect(page).to have_selector(".uv.en-gb")
    end
  end

  describe "raster_set" do
    with_queue_adapter :inline

    scenario "show page for raster set has a viewer with multiple tabs", js: true do
      scanned_map1 = FactoryBot.create_for_repository(:scanned_map_with_raster_children)
      scanned_map2 = FactoryBot.create_for_repository(:scanned_map_with_raster_children)
      map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map1.id, scanned_map2.id])
      change_set = ChangeSet.for(map_set)
      change_set.validate(state: "complete")
      ChangeSetPersister.default.save(change_set: change_set)

      # resource = FactoryBot.create_for_repository(:scanned_map_with_raster_children)

      visit solr_document_path(id: map_set.id)

      within_frame(find(".uv-container > iframe")) do
        expect(page).to have_selector(".uv.en-gb")
        # expect page to have tab
      end
    end
  end
end
