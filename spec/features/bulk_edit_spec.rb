# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Bulk edit", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:collection_title) { "My Collection" }
  let(:collection) { FactoryBot.create_for_repository(:collection, title: collection_title) }
  let(:member_scanned_resource) do
    FactoryBot.create_for_repository(:scanned_resource, title: ["Member Resource"], member_of_collection_ids: [collection.id])
  end
  let(:nonmember_scanned_resource) do
    FactoryBot.create_for_repository(:scanned_resource, title: ["Nonmember Resource"])
  end
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    stub_ezid

    [collection, member_scanned_resource, nonmember_scanned_resource].each do |resource|
      change_set = ChangeSet.for(resource)
      change_set_persister.save(change_set: change_set)
    end
    sign_in user
  end

  context "the bulk edit button" do
    it "will not display in an empty search" do
      visit root_path(q: "")

      expect(page).not_to have_css("#bulk-edit")
      expect(page).to have_content("My Collection")
      expect(page).to have_content("Member Resource")
      expect(page).to have_content("Nonmember Resource")
    end

    it "will display when a collection is selected" do
      visit root_path("q" => "", "f[member_of_collection_titles_ssim][]" => "My Collection")

      expect(page).to have_content("Member Resource")
      expect(page).not_to have_content("Nonmember Resource")
      expect(page).to have_css("#bulk-edit")
      # We can't test the whole href because it is constructed
      #   from path not as an absolute url
      link = page.find_link("Bulk Edit")
      uri = URI(link["href"])
      expect(uri.query).to eq "f%5Bmember_of_collection_titles_ssim%5D%5B%5D=My+Collection&q="
      expect(uri.path).to eq "/bulk_edit"
    end
    it "will display when a coin is selected" do
      visit root_path("q" => "", "f[human_readable_type_ssim][]" => "Coin")

      expect(page).to have_css("#bulk-edit")
      link = page.find_link("Bulk Edit")
      uri = URI(link["href"])
      expect(uri.query).to eq "f%5Bhuman_readable_type_ssim%5D%5B%5D=Coin&q="
      expect(uri.path).to eq "/bulk_edit"
    end
    it "will display when a scanned map is selected" do
      visit root_path("q" => "", "f[human_readable_type_ssim][]" => "Scanned Map")

      expect(page).to have_css("#bulk-edit")
      link = page.find_link("Bulk Edit")
      uri = URI(link["href"])
      expect(uri.query).to eq "f%5Bhuman_readable_type_ssim%5D%5B%5D=Scanned+Map&q="
      expect(uri.path).to eq "/bulk_edit"
    end
    it "will display when a vector resource is selected" do
      visit root_path("q" => "", "f[human_readable_type_ssim][]" => "Vector Resource")

      expect(page).to have_css("#bulk-edit")
      link = page.find_link("Bulk Edit")
      uri = URI(link["href"])
      expect(uri.query).to eq "f%5Bhuman_readable_type_ssim%5D%5B%5D=Vector+Resource&q="
      expect(uri.path).to eq "/bulk_edit"
    end
    it "will display when a raster resource is selected" do
      visit root_path("q" => "", "f[human_readable_type_ssim][]" => "Raster Resource")

      expect(page).to have_css("#bulk-edit")
      link = page.find_link("Bulk Edit")
      uri = URI(link["href"])
      expect(uri.query).to eq "f%5Bhuman_readable_type_ssim%5D%5B%5D=Raster+Resource&q="
      expect(uri.path).to eq "/bulk_edit"
    end
  end

  context "submit form" do
    with_queue_adapter :inline

    context "adding new embargo date" do
      let(:new_date) { (Time.zone.today + 12) }

      it "is updateable" do
        visit bulk_edit_resources_edit_path("q" => "", "f[member_of_collection_titles_ssim][]" => "My Collection")

        expect(page).to have_selector("#embargo-date-picker", visible: false)
        page.select "Input a date", from: "embargo_date_action", visible: false
        expect(page).to have_selector("#embargo-date-picker", visible: true)

        page.fill_in "embargo_date_value", with: new_date.strftime("%-m/%-d/%Y")
        accept_alert do
          click_button("Apply Edits")
        end

        expect(current_path).to eq root_path
        expect(page).to have_content "1 resources were queued for bulk update."
        updated = adapter.query_service.find_by(id: member_scanned_resource.id)

        # when entering a date via text into LuxDatePicker, the date will be one
        # day before. this doesn't happen when using the calendar UI and
        # recently when using capybara
        # see https://github.com/pulibrary/lux/issues/407 for details
        expect(updated.embargo_date).to eq new_date.strftime("%-m/%-d/%Y")
        expect(updated.member_of_collection_ids).to eq [collection.id]
      end
    end

    context "clearing an embargo date" do
      let(:resource_date) { (Time.zone.today + 2).strftime("%-m/%-d/%Y") }
      let(:member_scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, embargo_date: resource_date, member_of_collection_ids: [collection.id]) }

      it "is clearable" do
        visit bulk_edit_resources_edit_path("q" => "", "f[member_of_collection_titles_ssim][]" => "My Collection")

        page.select "Clear all values", from: "embargo_date_action", visible: false
        expect(page).to have_selector("#embargo-date-picker", visible: false)
        accept_alert do
          click_button("Apply Edits")
        end

        expect(current_path).to eq root_path
        expect(page).to have_content "1 resources were queued for bulk update."
        updated = adapter.query_service.find_by(id: member_scanned_resource.id)

        expect(updated.embargo_date).to eq ""
        expect(updated.member_of_collection_ids).to eq [collection.id]
      end
    end

    it "updates the object" do
      collection2 = FactoryBot.create_for_repository(:collection)
      visit bulk_edit_resources_edit_path("q" => "", "f[member_of_collection_titles_ssim][]" => "My Collection")
      expect(page).to have_content "Bulk edit 1 resources"
      page.check("mark_complete")
      page.select collection2.title.first, from: "append_collection_ids", visible: false
      page.select "No PDF", from: "pdf_type", visible: false
      accept_alert do
        click_button("Apply Edits")
      end
      expect(page).to have_content "1 resources were queued for bulk update."
      expect(current_path).to eq root_path
      updated = adapter.query_service.find_by(id: member_scanned_resource.id)
      expect(updated.state).to eq ["complete"]
      expect(updated.member_of_collection_ids).to eq [collection.id, collection2.id]
      expect(updated.pdf_type).to eq ["none"]
    end

    it "doesn't add a collection if one isn't picked" do
      FactoryBot.create_for_repository(:collection)
      visit bulk_edit_resources_edit_path("q" => "", "f[member_of_collection_titles_ssim][]" => "My Collection")
      expect(page).to have_content "You searched for"
      page.check("mark_complete")
      accept_alert do
        click_button("Apply Edits")
      end
      expect(page).to have_content "1 resources were queued for bulk update."
      expect(current_path).to eq root_path
      updated = adapter.query_service.find_by(id: member_scanned_resource.id)
      expect(updated.state).to eq ["complete"]
      expect(updated.member_of_collection_ids).to eq [collection.id]
    end

    context "with linked collections" do
      let(:collection2) { FactoryBot.create_for_repository(:collection, title: "Collection 2") }
      let(:member_scanned_resource) do
        FactoryBot.create_for_repository(:scanned_resource, title: ["Member Resource"], member_of_collection_ids: [collection.id, collection2.id])
      end

      before do
        change_set = ChangeSet.for(collection2)
        change_set_persister.save(change_set: change_set)
      end

      it "can only remove the collection that was not used to generate the bulk edit query" do
        visit bulk_edit_resources_edit_path("q" => "", "f[member_of_collection_titles_ssim][]" => "My Collection")
        page.check("mark_complete")
        expect(page).not_to have_xpath("//select[@id='remove_collection_ids']/option[text() = 'My Collection']")
        page.select collection2.title.first, from: "remove_collection_ids", visible: false
        accept_alert do
          click_button("Apply Edits")
        end
        expect(current_path).to eq root_path
        expect(page).to have_content "1 resources were queued for bulk update."
        updated = adapter.query_service.find_by(id: member_scanned_resource.id)
        expect(updated.member_of_collection_ids).to eq [collection.id]
      end
    end
  end
end
