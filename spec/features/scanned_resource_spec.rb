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
      # scanned_map1 = FactoryBot.create_for_repository(:scanned_map_with_raster_children)
      # scanned_map2 = FactoryBot.create_for_repository(:scanned_map_with_raster_children)
      # map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map1.id, scanned_map2.id])
      # change_set = ChangeSet.for(map_set)
      # change_set.validate(state: "complete")
      # ChangeSetPersister.default.save(change_set: change_set)

      # resource = FactoryBot.create_for_repository(:scanned_map_with_raster_children)

      file = IngestableFile.new(
        file_path: Rails.root.join("spec", "fixtures", "files", "raster", "geotiff.tif"),
        mime_type: "image/tif",
        original_filename: "geotiff.tif",
        container_attributes: { service_targets: "tiles" }
      )
      file2 = file.new({}) # Duplicates file.
      raster = FactoryBot.create_for_repository(:raster_resource, state: "complete", files: [file])
      raster2 = FactoryBot.create_for_repository(:raster_resource, state: "complete", files: [file2])

      # raster = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
      # raster2 = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")

      change_set = ChangeSet.for(raster)
      ChangeSetPersister.default.save(change_set: change_set)

      change_set = ChangeSet.for(raster2)
      ChangeSetPersister.default.save(change_set: change_set)


      file = fixture_file_upload("files/abstract.tiff", "image/tiff")
      scanned_map = FactoryBot.create_for_repository(:scanned_map, member_ids: [raster.id], files: [file])
      change_set = ChangeSet.for(scanned_map)
      change_set.validate(state: "complete")
      ChangeSetPersister.default.save(change_set: change_set)

      file2 = fixture_file_upload("files/abstract.tiff", "image/tiff")
      scanned_map2 = FactoryBot.create_for_repository(:scanned_map, member_ids: [raster2.id], files: [file2])
      change_set = ChangeSet.for(scanned_map2)
      change_set.validate(state: "complete")
      ChangeSetPersister.default.save(change_set: change_set)

      map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map.id, scanned_map2.id])
      change_set = ChangeSet.for(map_set)
      change_set.validate(state: "complete")
      ChangeSetPersister.default.save(change_set: change_set)

      visit solr_document_path(id: map_set.id)

      within_frame(find(".uv-container > iframe")) do
        expect(page).to have_selector(".uv.en-gb")
        # expect page to have tab
        binding.pry
      end
    end
  end
end
