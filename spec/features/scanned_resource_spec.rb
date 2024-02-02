# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Scanned Resource" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_ezid

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
      expect(page).to have_selector(".uv-iiif-extension-host.en-gb")
    end
  end

  scenario "show page has a health status" do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])

    visit solr_document_path(id: resource.id)
    expect(page).to have_selector("#health-status")
  end

  scenario "show page can display confetti" do
    resource = FactoryBot.create_for_repository(:pending_scanned_resource)
    ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))

    visit solr_document_path(id: resource.id)

    choose("Complete")
    click_button("Submit")

    expect(page).to have_selector("*[data-confetti-trigger]")
  end

  scenario "resource with file sets that are in process can't complete" do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:pending_scanned_resource, files: [file])

    visit solr_document_path(id: resource.id)
    expect(page).to have_css(".disable-final-state")
    expect(page).to have_text("Resource can't be completed while derivatives are in-process")
  end
end
