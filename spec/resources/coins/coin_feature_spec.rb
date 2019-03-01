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
  let(:numismatic_issue) do
    res = FactoryBot.create_for_repository(:numismatic_issue, member_ids: [coin.id])
    persister.save(resource: res)
  end
  let(:change_set) do
    CoinChangeSet.new(coin)
    NumismaticIssueChangeSet.new(numismatic_issue)
  end
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    stub_ezid(shoulder: "99999/fk4", blade: "123456")

    change_set_persister.save(change_set: change_set)
    sign_in user
  end

  describe "breadcrumbs" do
    before do
      coin
      sign_in(user)
    end
    it "shows parent when there is no parent param in the url" do
      visit solr_document_path(coin)
      expect(page).to have_css ".breadcrumb", text: "#{numismatic_issue.title.join} #{coin.title.join}"
      expect(page).to have_selector("#doc_#{coin.id} > ol > li:nth-child(1) > a")
      expect(page).to have_link "Issue: 1", href: solr_document_path(numismatic_issue)
    end
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
    expect(page).to have_field "Numismatic collection"
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
        die_axis: "test value",
        find_date: "test value",
        find_description: "test value",
        find_feature: "test value",
        find_locus: "test value",
        find_number: "test value",
        find_place: "test value",
        holding_location: "test value",
        loan: "test value",
        private_note: "test value",
        numismatic_collection: "test value",
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
      expect(page).to have_css ".attribute.die_axis", text: "test value"
      expect(page).to have_css ".attribute.find_date", text: "test value"
      expect(page).to have_css ".attribute.find_description", text: "test value"
      expect(page).to have_css ".attribute.find_feature", text: "test value"
      expect(page).to have_css ".attribute.find_locus", text: "test value"
      expect(page).to have_css ".attribute.find_number", text: "test value"
      expect(page).to have_css ".attribute.find_place", text: "test value"
      expect(page).to have_css ".attribute.holding_location", text: "test value"
      expect(page).to have_css ".attribute.loan", text: "test value"
      expect(page).to have_css ".attribute.numismatic_collection", text: "test value"
      expect(page).to have_css ".attribute.private_note", text: "test value"
      expect(page).to have_css ".attribute.provenance", text: "test value"
      expect(page).to have_css ".attribute.replaces", text: "test value"
      expect(page).to have_css ".attribute.size", text: "test value"
      expect(page).to have_css ".attribute.technique", text: "test value"
      expect(page).to have_css ".attribute.weight", text: "test value"
    end
  end

  context "when a coin has citation and artist" do
    let(:coin) { FactoryBot.create_for_repository(:coin, numismatic_artist_ids: [artist.id]) }
    let(:artist) { FactoryBot.create_for_repository(:numismatic_artist) }

    before do
      visit solr_document_path coin
    end

    it "displays Add Citation button" do
      expect(page).to have_css("#doc_#{coin.id} > a", text: "Add Citation")
      expect(page).to have_link "Add Citation", href: parent_add_numismatic_citation_path(coin, parent_id: coin.id)
    end

    it "displays Add Artist button" do
      expect(page).to have_css("#doc_#{coin.id} > a", text: "Add Artist")
      expect(page).to have_link "Add Artist", href: parent_add_numismatic_artist_path(coin, parent_id: coin.id)
    end
  end
end
