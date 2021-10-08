# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Related Resources", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }

  before do
    sign_in user
  end

  context "on a scanned resource parent show page" do
    it "can attach and detach a member" do
      parent = persister.save(resource: FactoryBot.create_for_repository(:scanned_resource))
      child = persister.save(resource: FactoryBot.create_for_repository(:scanned_resource))

      # attach
      visit "/catalog/#{parent.id}"
      fill_in("scanned_resource[member_ids]", with: child.id.to_s)
      click_on("button")

      # wait for the new row to load so we get through the controller before we
      # look for the new object
      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [child.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end
  end

  context "on a vector resource parent show page" do
    it "can attach and detach a child vector" do
      parent = persister.save(resource: FactoryBot.create_for_repository(:vector_resource))
      child = persister.save(resource: FactoryBot.create_for_repository(:vector_resource))

      # attach
      visit "/catalog/#{parent.id}"
      child_vector_panel = page.find("#members-vector-resources-panel")

      within child_vector_panel do
        fill_in("vector_resource[member_ids]", with: child.id.to_s)
        click_on("button")
      end

      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [child.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end

    it "can attach and detach a parent vector" do
      resource = persister.save(resource: FactoryBot.create_for_repository(:vector_resource))
      parent = persister.save(resource: FactoryBot.create_for_repository(:vector_resource))

      # attach
      visit "/catalog/#{resource.id}"
      fill_in("parent_vector_resource_id_input", with: parent.id.to_s)
      click_on("parent_vector_resource_button")

      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [resource.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end

    it "can attach and detach a parent raster" do
      resource = persister.save(resource: FactoryBot.create_for_repository(:raster_resource))
      parent = persister.save(resource: FactoryBot.create_for_repository(:raster_resource))

      # attach
      visit "/catalog/#{resource.id}"
      fill_in("parent_raster_resource_id_input", with: parent.id.to_s)
      click_on("parent_raster_resource_button")

      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [resource.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end
  end

  context "on a raster resource parent show page" do
    it "can attach and detach a child raster" do
      parent = persister.save(resource: FactoryBot.create_for_repository(:raster_resource))
      child = persister.save(resource: FactoryBot.create_for_repository(:raster_resource))

      # attach
      visit "/catalog/#{parent.id}"
      fill_in("child_raster_resource_id_input", with: child.id.to_s)
      click_on("child_raster_resource_button")

      # wait for the new row to load so we get through the controller before we
      # look for the new object
      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [child.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end

    it "can attach and detach a child vector" do
      parent = persister.save(resource: FactoryBot.create_for_repository(:raster_resource))
      child = persister.save(resource: FactoryBot.create_for_repository(:vector_resource))

      # attach
      visit "/catalog/#{parent.id}"
      fill_in("child_vector_resource_id_input", with: child.id.to_s)
      click_on("child_vector_resource_button")

      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [child.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end

    it "can attach and detach a parent raster" do
      resource = persister.save(resource: FactoryBot.create_for_repository(:raster_resource))
      parent = persister.save(resource: FactoryBot.create_for_repository(:raster_resource))

      # attach
      visit "/catalog/#{resource.id}"
      fill_in("parent_raster_resource_id_input", with: parent.id.to_s)
      click_on("parent_raster_resource_button")

      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [resource.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end

    it "can attach and detach a parent scanned map" do
      resource = persister.save(resource: FactoryBot.create_for_repository(:raster_resource))
      parent = persister.save(resource: FactoryBot.create_for_repository(:scanned_map))

      # attach
      visit "/catalog/#{resource.id}"
      fill_in("parent_scanned_map_resource_id_input", with: parent.id.to_s)
      click_on("parent_scanned_map_resource_button")

      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [resource.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end
  end

  context "on a scanned map resource parent show page" do
    it "can attach and detach a child scanned map" do
      parent = persister.save(resource: FactoryBot.create_for_repository(:scanned_map))
      child = persister.save(resource: FactoryBot.create_for_repository(:scanned_map))

      # attach
      visit "/catalog/#{parent.id}"
      fill_in("child_scanned_map_resource_id_input", with: child.id.to_s)
      click_on("child_scanned_map_resource_button")

      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [child.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end

    it "can attach and detach a child raster" do
      parent = persister.save(resource: FactoryBot.create_for_repository(:scanned_map))
      child = persister.save(resource: FactoryBot.create_for_repository(:raster_resource))

      # attach
      visit "/catalog/#{parent.id}"
      fill_in("child_raster_resource_id_input", with: child.id.to_s)
      click_on("child_raster_resource_button")

      # wait for the new row to load so we get through the controller before we
      # look for the new object
      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [child.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end

    it "can attach and detach a parent scanned map" do
      resource = persister.save(resource: FactoryBot.create_for_repository(:scanned_map))
      parent = persister.save(resource: FactoryBot.create_for_repository(:scanned_map))

      # attach
      visit "/catalog/#{resource.id}"
      fill_in("parent_scanned_map_resource_id_input", with: parent.id.to_s)
      click_on("parent_scanned_map_resource_button")

      new_row = page.find("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members.map(&:id)).to eq [resource.id]

      # detach
      within new_row do
        click_on("button")
      end

      # wait for page change
      expect(page).not_to have_selector("tr[data-resource-id]")

      parent = adapter.query_service.find_by(id: parent.id)
      expect(Wayfinder.for(parent).members).to be_empty
    end
  end
end
