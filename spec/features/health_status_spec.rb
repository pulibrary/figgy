# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Heath Status" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_ezid

    sign_in user
  end

  scenario "resource with an errored fileset displays problematic resources", js: true do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, files: [file])
    file_set = Wayfinder.for(resource).file_sets.first
    file_set.primary_file.error_message = "Broken!"
    ChangeSetPersister.default.metadata_adapter.persister.save(resource: file_set)

    visit solr_document_path(id: resource.id)
    expect(page).to have_selector("#health-status")

    find('a[data-target="#healthModal"]').click
    expect(page).to have_selector("div", text: "Derivative Status: Needs Attention")
    expect(page).not_to have_button("Hide Problematic Resources")
    expect(page).not_to have_link(resource.title.first, href: /concern\/scanned_resources\/#{resource.id}\/file_manager/, target: "_blank")

    find("button", text: "Show Problematic Resources").click
    expect(page).to have_button("Hide Problematic Resources")
    expect(page).to have_link(resource.title.first, href: /concern\/scanned_resources\/#{resource.id}\/file_manager/, target: "_blank")

    find("button", text: "Hide Problematic Resources").click
    expect(page).to have_button("Show Problematic Resources")
  end

  scenario "resource with a failed local fixity fileset displays problematic resources", js: true do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, files: [file])
    file_set = Wayfinder.for(resource).file_sets.first
    FactoryBot.create(:local_fixity_failure, resource_id: file_set.id)

    visit solr_document_path(id: resource.id)
    expect(page).to have_selector("#health-status")

    find('a[data-target="#healthModal"]').click
    expect(page).to have_selector("div", text: "Local Fixity Status: Needs Attention")

    find("button", text: "Show Problematic Resources").click
    expect(page).to have_link(resource.title.first, href: /concern\/scanned_resources\/#{resource.id}\/file_manager/, target: "_blank")
  end

  scenario "resource with a failed cloud fixity fileset displays problematic resources", js: true do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, files: [file])
    file_set = Wayfinder.for(resource).file_sets.first
    create_preservation_object(event_status: Event::FAILURE, resource_id: file_set.id, event_type: :cloud_fixity)

    visit solr_document_path(id: resource.id)
    expect(page).to have_selector("#health-status")

    find('a[data-target="#healthModal"]').click
    expect(page).to have_selector("div", text: "Cloud Fixity Status: Needs Attention")

    find("button", text: "Show Problematic Resources").click
    expect(page).to have_link(resource.title.first, href: /concern\/scanned_resources\/#{resource.id}\/file_manager/, target: "_blank")
  end

  scenario "resource with failed cloud fixity event on it's metadata displays problematic resources", js: true do
    file = fixture_file_upload("files/example.tif", "image/tiff")
    resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, files: [file])
    create_preservation_object(resource_id: resource.id, event_status: Event::FAILURE, event_type: :cloud_fixity)

    visit solr_document_path(id: resource.id)
    expect(page).to have_selector("#health-status")

    find('a[data-target="#healthModal"]').click
    expect(page).to have_selector("div", text: "Cloud Fixity Status: Needs Attention")

    find("button", text: "Show Problematic Resources").click
    expect(page).to have_link(resource.title.first, href: /catalog\/#{resource.id}/, target: "_blank")
  end

  def create_preservation_object(event_status:, resource_id:, event_type:)
    metadata_node = FileMetadata.new(id: SecureRandom.uuid)
    preservation_object = FactoryBot.create_for_repository(:preservation_object, preserved_object_id: resource_id, metadata_node: metadata_node)
    FactoryBot.create_for_repository(
      :event,
      type: event_type,
      status: event_status,
      resource_id: preservation_object.id,
      child_id: metadata_node.id,
      child_property: :metadata_node,
      current: true
    )
  end
end
