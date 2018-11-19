# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Coins" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:coin) do
    res = FactoryBot.create_for_repository(:coin)
    persister.save(resource: res)
  end
  let(:change_set) do
    CoinChangeSet.new(coin)
  end
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    stub_ezid(shoulder: "99999/fk4", blade: "123456")

    change_set_persister.save(change_set: change_set)
    sign_in user
  end

  scenario "creating a new resource" do
    visit new_coin_path

    expect(page).to have_field "Accession"
    expect(page).to have_field "Analysis"
    expect(page).to have_field "Counter stamp"
    expect(page).to have_field "Die axis"
    expect(page).to have_field "Find date"
    expect(page).to have_field "Find description"
    expect(page).to have_field "Find feature"
    expect(page).to have_field "Find locus"
    expect(page).to have_field "Find number"
    expect(page).to have_field "Find place"
    expect(page).to have_field "Holding Location"
    expect(page).not_to have_css '.select[for="coin_holding_location"]', text: "Holding Location"
    expect(page).to have_field "Loan"
    expect(page).to have_field "Object type"
    expect(page).to have_field "Place"
    expect(page).to have_field "Private note"
    expect(page).to have_field "Provenance"
    expect(page).to have_field "Size"
    expect(page).to have_field "Technique"
    expect(page).to have_field "Weight"

    fill_in "Size", with: "3 cm"
    click_button "Save"

    expect(page).to have_content "3 cm"
  end

  context "when a user creates a new coin" do
    let(:coin) do
      FactoryBot.create_for_repository(
        :coin,
        accession_number: 123,
        analysis: "test value",
        counter_stamp: "test value",
        department: "test value",
        die_axis: "test value",
        find_date: "test value",
        find_description: "test value",
        find_feature: "test value",
        find_locus: "test value",
        find_number: "test value",
        find_place: "test value",
        holding_location: "test value",
        loan: "test value",
        object_type: "test value",
        place: "test value",
        private_note: "test value",
        provenance: "test value",
        replaces: "test value",
        size: "test value",
        technique: "test value",
        weight: "test value"
      )
    end

    scenario "viewing a resource" do
      visit solr_document_path coin

      expect(page).to have_css ".attribute.visibility", text: "open"
      expect(page).to have_css ".attribute.accession_number", text: 123
      expect(page).to have_css ".attribute.analysis", text: "test value"
      expect(page).to have_css ".attribute.counter_stamp", text: "test value"
      expect(page).to have_css ".attribute.department", text: "test value"
      expect(page).to have_css ".attribute.die_axis", text: "test value"
      expect(page).to have_css ".attribute.find_date", text: "test value"
      expect(page).to have_css ".attribute.find_description", text: "test value"
      expect(page).to have_css ".attribute.find_feature", text: "test value"
      expect(page).to have_css ".attribute.find_locus", text: "test value"
      expect(page).to have_css ".attribute.find_number", text: "test value"
      expect(page).to have_css ".attribute.find_place", text: "test value"
      expect(page).to have_css ".attribute.holding_location", text: "test value"
      expect(page).to have_css ".attribute.loan", text: "test value"
      expect(page).to have_css ".attribute.object_type", text: "test value"
      expect(page).to have_css ".attribute.place", text: "test value"
      expect(page).to have_css ".attribute.private_note", text: "test value"
      expect(page).to have_css ".attribute.provenance", text: "test value"
      expect(page).to have_css ".attribute.replaces", text: "test value"
      expect(page).to have_css ".attribute.size", text: "test value"
      expect(page).to have_css ".attribute.technique", text: "test value"
      expect(page).to have_css ".attribute.weight", text: "test value"
    end
  end
end
