# frozen_string_literal: true
require "rails_helper"

RSpec.feature "NumismaticIssues" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:numismatic_issue) do
    res = FactoryBot.create_for_repository(:numismatic_issue)
    persister.save(resource: res)
  end
  let(:change_set) do
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

  scenario "creating a new resource" do
    visit new_numismatic_issue_path

    expect(page).to have_css '.select[for="numismatic_issue_rights_statement"]', text: "Rights Statement"
    expect(page).to have_field "Rights Note"
    expect(page).to have_css '.select[for="numismatic_issue_member_of_collection_ids"]', text: "Collections"
    expect(page).to have_field "Artist"
    expect(page).to have_field "Color"
    expect(page).to have_field "Date of object"
    expect(page).to have_field "Date start" # For the date range sequence
    expect(page).to have_field "Date end" # For the date range
    expect(page).to have_field "Denomination"
    expect(page).to have_field "Description"
    expect(page).to have_field "Edge"
    expect(page).to have_field "Era"
    expect(page).to have_field "Geographic origin"
    expect(page).to have_field "Master"
    expect(page).to have_field "Metal"
    expect(page).to have_field "Note"
    expect(page).to have_field "Object type"
    expect(page).to have_field "Obverse attributes"
    expect(page).to have_field "Obverse figure"
    expect(page).to have_field "Obverse figure description"
    expect(page).to have_field "Obverse figure relationship"
    expect(page).to have_field "Obverse legend"
    expect(page).to have_field "Obverse orientation"
    expect(page).to have_field "Obverse part"
    expect(page).to have_field "Obverse symbol"
    expect(page).to have_field "Place"
    expect(page).to have_field "Reverse attributes"
    expect(page).to have_field "Reverse figure"
    expect(page).to have_field "Obverse figure description"
    expect(page).to have_field "Reverse figure relationship"
    expect(page).to have_field "Reverse legend"
    expect(page).to have_field "Reverse orientation"
    expect(page).to have_field "Reverse part"
    expect(page).to have_field "Reverse symbol"
    expect(page).to have_field "Ruler"
    expect(page).to have_field "Series"
    expect(page).to have_field "Shape"
    expect(page).to have_field "Subject"
    expect(page).to have_field "Workshop"

    fill_in "Object type", with: "ancient coin"
    click_button "Save"

    expect(page).to have_content "ancient coin"
  end

  context "when a user creates a new numismatic issue" do
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:numismatic_issue) do
      FactoryBot.create_for_repository(
        :numismatic_issue,
        rights_statement: RightsStatements.copyright_not_evaluated.to_s,
        member_of_collection_ids: [collection.id],
        artist: "test value",
        color: "test value",
        date_range: DateRange.new(start: "2017", end: "2018"),
        denomination: "test value",
        description: "test value",
        edge: "test value",
        era: "test value",
        geographic_origin: "test value",
        master: "test value",
        metal: "test value",
        note: "test value",
        object_date: "test value",
        object_type: "test value",
        obverse_attributes: "test value",
        obverse_figure: "test value",
        obverse_figure_description: "test value",
        obverse_figure_relationship: "test value",
        obverse_legend: "test value",
        obverse_orientation: "test value",
        obverse_part: "test value",
        obverse_symbol: "test value",
        place: "test value",
        replaces: "test value",
        reverse_attributes: "test value",
        reverse_figure: "test value",
        reverse_figure_description: "test value",
        reverse_figure_relationship: "test value",
        reverse_legend: "test value",
        reverse_orientation: "test value",
        reverse_part: "test value",
        reverse_symbol: "test value",
        ruler: "test value",
        series: "test value",
        shape: "test value",
        subject: "test value",
        workshop: "test value"
      )
    end

    scenario "viewing a resource" do
      visit solr_document_path numismatic_issue

      expect(page).to have_css ".attribute.rendered_rights_statement", text: "Copyright Not Evaluated"
      expect(page).to have_css ".attribute.visibility", text: "open"
      expect(page).to have_css ".attribute.member_of_collections", text: "Title"
      expect(page).to have_css ".attribute.artist", text: "test value"
      expect(page).to have_css ".attribute.color", text: "test value"
      expect(page).to have_css ".attribute.rendered_date_range", text: "2017-2018"
      expect(page).to have_css ".attribute.denomination", text: "test value"
      expect(page).to have_css ".attribute.description", text: "test value"
      expect(page).to have_css ".attribute.edge", text: "test value"
      expect(page).to have_css ".attribute.era", text: "test value"
      expect(page).to have_css ".attribute.geographic_origin", text: "test value"
      expect(page).to have_css ".attribute.master", text: "test value"
      expect(page).to have_css ".attribute.metal", text: "test value"
      expect(page).to have_css ".attribute.note", text: "test value"
      expect(page).to have_css ".attribute.object_date", text: "test value"
      expect(page).to have_css ".attribute.object_type", text: "test value"
      expect(page).to have_css ".attribute.obverse_attributes", text: "test value"
      expect(page).to have_css ".attribute.obverse_figure", text: "test value"
      expect(page).to have_css ".attribute.obverse_figure_relationship", text: "test value"
      expect(page).to have_css ".attribute.obverse_figure_description", text: "test value"
      expect(page).to have_css ".attribute.obverse_legend", text: "test value"
      expect(page).to have_css ".attribute.obverse_orientation", text: "test value"
      expect(page).to have_css ".attribute.obverse_part", text: "test value"
      expect(page).to have_css ".attribute.obverse_symbol", text: "test value"
      expect(page).to have_css ".attribute.place", text: "test value"
      expect(page).to have_css ".attribute.replaces", text: "test value"
      expect(page).to have_css ".attribute.reverse_attributes", text: "test value"
      expect(page).to have_css ".attribute.reverse_figure", text: "test value"
      expect(page).to have_css ".attribute.reverse_figure_relationship", text: "test value"
      expect(page).to have_css ".attribute.reverse_figure_description", text: "test value"
      expect(page).to have_css ".attribute.reverse_legend", text: "test value"
      expect(page).to have_css ".attribute.reverse_orientation", text: "test value"
      expect(page).to have_css ".attribute.reverse_part", text: "test value"
      expect(page).to have_css ".attribute.reverse_symbol", text: "test value"
      expect(page).to have_css ".attribute.ruler", text: "test value"
      expect(page).to have_css ".attribute.series", text: "test value"
      expect(page).to have_css ".attribute.shape", text: "test value"
      expect(page).to have_css ".attribute.subject", text: "test value"
      expect(page).to have_css ".attribute.workshop", text: "test value"
    end
  end

  context "with child Coin resources" do
    let(:member) do
      persister.save(resource: FactoryBot.create_for_repository(:coin))
    end
    let(:parent) do
      persister.save(resource: FactoryBot.create_for_repository(:numismatic_issue, member_ids: [member.id]))
    end
    before do
      parent
    end

    scenario "saved Coins are displayed as members" do
      visit solr_document_path(parent)

      expect(page).to have_selector "h2", text: "Coins"
      expect(page).to have_selector "td", text: "Coin: #{member.coin_number}"
    end
  end
end
