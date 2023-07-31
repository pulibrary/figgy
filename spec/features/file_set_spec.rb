# frozen_string_literal: true
require "rails_helper"

RSpec.feature "FileSet" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_ezid

    sign_in user
  end

  scenario "file set show page has a health status" do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
    file_set = Wayfinder.for(resource).file_sets.first

    visit solr_document_path(id: file_set.id)
    expect(page).to have_selector("#health-status")
  end

  scenario "file set show page has a health status" do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
    file_set = Wayfinder.for(resource).file_sets.first

    visit solr_document_path(id: file_set.id)
    expect(page).to have_selector("#health-status")
  end

  scenario "fileset fixity ui table shows the Last Success if it's a preserved file" do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
    file_set = Wayfinder.for(resource).file_sets.first

    visit solr_document_path(id: file_set.id)
    expect(page).to have_css ".preserved", text: "Last Success:"
  end

  scenario "fileset fixity ui table informs the user of any files that are intentionally not preserved" do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
    file_set = Wayfinder.for(resource).file_sets.first

    visit solr_document_path(id: file_set.id)
    expect(page).to have_css ".not_preserved", text: "Derivative files are not preserved."
  end
end
