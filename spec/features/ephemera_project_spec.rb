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
    expect(page).to have_css "li.rendered_banner_image > img[src=\"#{project.banner_image_url}\"]"
    reloaded_folder = ChangeSetPersister.default.query_service.find_by(id: folder.id)
    expect(reloaded_folder.updated_at).to eq folder.updated_at
  end

  context "viewing a project" do
    scenario "with a banner image url" do
      project = FactoryBot.create_for_repository(:ephemera_project)
      visit solr_document_path(id: project.id)
      expect(page).to have_text "Rendered Banner Image"
      expect(page).to have_css "li.rendered_banner_image > img"
    end
    scenario "without a banner image url" do
      project = FactoryBot.create_for_repository(:ephemera_project, banner_image_url: nil)
      visit solr_document_path(id: project.id)
      expect(page).not_to have_text "Rendered Banner Image"
      expect(page).not_to have_css "li.rendered_banner_image > img"
    end
  end
end
