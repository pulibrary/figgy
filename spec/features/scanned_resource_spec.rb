require "rails_helper"

RSpec.feature "Scanned Resource" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_ezid

    sign_in user
  end

  scenario "edit a resource", js: true do
    resource = FactoryBot.create_for_repository(:scanned_resource)
    visit edit_scanned_resource_path(id: resource.id)

    # Access and display section
    expect(page).to have_content "Access and Display"
    expect(page).to have_content "Feature in Digital Collections"
    expect(page).to have_content "Add this resource to a collection to make it available for highlighting."
    expect(page).to have_content "Embargo Date"
  end

  scenario "highlighting a resource in specific collections", js: true do
    collection1 = FactoryBot.create_for_repository(:collection, title: "First Collection")
    collection2 = FactoryBot.create_for_repository(:collection, title: "Second Collection")
    resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection1.id])
    visit edit_scanned_resource_path(id: resource.id)

    # Only the collections the resource belongs to are offered.
    within ".featurable-collections" do
      expect(page).to have_field "First Collection", type: "checkbox"
      expect(page).not_to have_field "Second Collection", type: "checkbox"
      check "First Collection"
    end

    # Adding a collection adds a checkbox without a round trip.
    collection_dropdown = page.find(:css, '[data-id="scanned_resource_member_of_collection_ids"]')
    collection_dropdown.click
    within first("div.dropdown-menu.show") do
      find("a[role='option']", text: "Second Collection").click
    end
    collection_dropdown.click # close the dropdown
    within ".featurable-collections" do
      expect(page).to have_field "Second Collection", type: "checkbox", checked: false
      expect(page).to have_field "First Collection", type: "checkbox", checked: true
    end

    click_button "Save"
    expect(page).to have_content "Title"

    reloaded = ChangeSetPersister.default.query_service.find_by(id: resource.id)
    expect(reloaded.featurable.map(&:to_s)).to eq [collection1.id.to_s]
  end

  scenario "editing a resource that still has the old boolean featurable value", js: true do
    collection = FactoryBot.create_for_repository(:collection, title: "Legacy Collection")
    resource = FactoryBot.create_for_repository(
      :scanned_resource,
      member_of_collection_ids: [collection.id],
      featurable: "1"
    )
    visit edit_scanned_resource_path(id: resource.id)

    within ".featurable-collections" do
      expect(page).to have_field "Legacy Collection", type: "checkbox", checked: false
    end
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

  scenario "creating a selene resource from a scanned resource with file set" do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    scanned_resource = FactoryBot.create_for_repository(:final_review_scanned_resource, visibility: AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ON_CAMPUS, files: [file])
    file_set = scanned_resource.decorate.file_sets.first
    visit file_set_new_selene_resource_path(parent_id: file_set.id)

    click_button "Save"

    id = page.current_url.split("/").last
    selene = ChangeSetPersister.default.query_service.find_by(id: id)
    expect(selene.visibility).to eq scanned_resource.visibility
    expect(selene.state).to eq scanned_resource.state
  end
end
