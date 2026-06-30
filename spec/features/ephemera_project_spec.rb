require "rails_helper"

RSpec.feature "Ephemera Project" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  scenario "editing a project", js: true do
    folder = FactoryBot.create_for_repository(:ephemera_folder)
    project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [folder.id])
    visit edit_ephemera_project_path(id: project.id)

    # edit fields
    expect(page).to have_field "Title", with: project.title.first
    expect(page).to have_field "DPUL URL", with: project.slug.first
    expect(page).to have_checked_field "Publish in Digital Collections"
    expect(page).to have_content "External Depositors"
    expect(page).to have_field "Tagline", with: project.tagline.first

    # renders rich text editor for description
    element = find("trix-editor > div")
    expect(element.text).to eq project.description.first

    # Has hidden banner image url field
    element = find('#ephemera_project_banner_image_url', visible: false)
    expect(element.value).to eq project.banner_image_url
    # This .openseadragon-container element only gets created
    # when the Vue component successfully renders
    expect(page).to have_css '.openseadragon-container'

    click_button "Save"

    expect(page).to have_link "Delete This Ephemera Project"
    # Expect the banner_image_url to be the same
    expect(page).to have_css "td.rendered_banner_image > img[src=\"#{project.banner_image_url}\"]"
    reloaded_folder = ChangeSetPersister.default.query_service.find_by(id: folder.id)
    expect(reloaded_folder.updated_at).to eq folder.updated_at
  end

  context "viewing a project" do
    scenario "when published with a banner image url" do
      project = FactoryBot.create_for_repository(:ephemera_project, publish: true)
      visit solr_document_path(id: project.id)
      expect(page).to have_text "Banner Image"
      expect(page).to have_css "td.rendered_banner_image > img"
      expect(page).to have_text "Digital Collections URL"
      expect(page).to have_css "td.rendered_dc_url > a[href=\"https://digital-collections.princeton.edu/collections/test_project-1234\"]"
      expect(page).to have_text "DPUL URL"
      expect(page).to have_css "td.rendered_dpul_url > a[href=\"https://dpul.princeton.edu/test_project-1234\"]"
    end

    scenario "when unpublished and without a banner image url" do
      project = FactoryBot.create_for_repository(:ephemera_project, banner_image_url: nil, publish: false)
      visit solr_document_path(id: project.id)
      expect(page).not_to have_text "Banner Image"
      expect(page).not_to have_css "td.rendered_banner_image > img"
      expect(page).not_to have_text "Digital Collections URL"
      expect(page).not_to have_css "td.rendered_dc_url > a[href=\"https://digital-collections.princeton.edu/collections/test_project-1234\"]"
    end

    scenario "with a highlighted item" do
      folder = FactoryBot.create_for_repository(:ephemera_folder, title: "Featured Folder", featurable: "0")
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [folder.id])
      visit edit_ephemera_folder_path(id: folder.id)
      check "Feature in Digital Collections"
      click_button "Save"
      visit solr_document_path(id: project.id)
      click_link "View Highlighted Items"
      expect(page).to have_text "Featured Folder"
    end
  end
end
