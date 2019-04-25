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
    expect(page).to have_field "Color"
    expect(page).to have_field "Date of object"
    expect(page).to have_field "Ce1" # For the date range sequence
    expect(page).to have_field "Ce2" # For the date range
    expect(page).to have_field "Description"
    expect(page).to have_field "Denomination"
    expect(page).to have_field "Edge"
    expect(page).to have_field "Era"
    expect(page).to have_field "Master"
    expect(page).to have_field "Metal"
    expect(page).to have_field "Name"
    expect(page).to have_field "Note"
    expect(page).to have_field "Number"
    expect(page).to have_field "Numismatic Reference"
    expect(page).to have_field "Part"
    expect(page).to have_field "Person"
    expect(page).to have_field "Place"
    expect(page).to have_field "Object type"
    expect(page).to have_field "Obverse figure"
    expect(page).to have_field "Obverse figure description"
    expect(page).to have_field "Obverse figure relationship"
    expect(page).to have_field "Obverse legend"
    expect(page).to have_field "Obverse orientation"
    expect(page).to have_field "Obverse part"
    expect(page).to have_field "Obverse symbol"
    expect(page).to have_field "Reverse figure"
    expect(page).to have_field "Reverse figure description"
    expect(page).to have_field "Reverse figure relationship"
    expect(page).to have_field "Reverse legend"
    expect(page).to have_field "Reverse orientation"
    expect(page).to have_field "Reverse part"
    expect(page).to have_field "Reverse symbol"
    expect(page).to have_field "Role"
    expect(page).to have_field "Ruler"
    expect(page).to have_field "Series"
    expect(page).to have_field "Shape"
    expect(page).to have_field "Side"
    expect(page).to have_field "Signature"
    expect(page).to have_field "State"
    expect(page).to have_field "Subject"
    expect(page).to have_field "Type"
    expect(page).to have_field "Workshop"

    fill_in "Object type", with: "ancient coin"
    click_button "Save"

    expect(page).to have_content "ancient coin"
  end

  context "when a user creates a new numismatic issue" do
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:numismatic_reference) { FactoryBot.create_for_repository(:numismatic_reference) }
    let(:person) { FactoryBot.create_for_repository(:numismatic_person) }
    let(:numismatic_artist) { NumismaticArtist.new(person_id: person.id, signature: "artist signature") }
    let(:numismatic_attribute) { NumismaticAttribute.new(description: "attribute description", name: "attribute name") }
    let(:numismatic_note) { NumismaticNote.new(note: "note", type: "note type") }
    let(:numismatic_citation) { NumismaticCitation.new(part: "part", number: "number", numismatic_reference_id: numismatic_reference.id) }
    let(:numismatic_place) { FactoryBot.create_for_repository(:numismatic_place) }
    let(:numismatic_person) { FactoryBot.create_for_repository(:numismatic_person) }
    let(:numismatic_subject) { NumismaticSubject.new(type: "Animal", subject: "unicorn") }
    let(:numismatic_issue) do
      FactoryBot.create_for_repository(
        :numismatic_issue,
        rights_statement: RightsStatements.copyright_not_evaluated.to_s,
        member_of_collection_ids: [collection.id],
        numismatic_place_id: numismatic_place.id,
        numismatic_artist: numismatic_artist,
        numismatic_citation: numismatic_citation,
        numismatic_note: numismatic_note,
        numismatic_subject: numismatic_subject,
        obverse_attribute: numismatic_attribute,
        reverse_attribute: numismatic_attribute,
        ruler_id: numismatic_person.id,
        master_id: numismatic_person.id,
        ce1: "2017",
        ce2: "2018",
        color: "test value",
        denomination: "test value",
        edge: "test value",
        era: "test value",
        metal: "test value",
        object_date: "test value",
        object_type: "test value",
        obverse_figure: "test value",
        obverse_figure_description: "test value",
        obverse_figure_relationship: "test value",
        obverse_legend: "test value",
        obverse_orientation: "test value",
        obverse_part: "test value",
        obverse_symbol: "test value",
        replaces: "test value",
        reverse_figure: "test value",
        reverse_figure_description: "test value",
        reverse_figure_relationship: "test value",
        reverse_legend: "test value",
        reverse_orientation: "test value",
        reverse_part: "test value",
        reverse_symbol: "test value",
        series: "test value",
        shape: "test value",
        workshop: "test value"
      )
    end

    scenario "viewing a resource" do
      visit solr_document_path numismatic_issue
      expect(page).to have_css ".attribute.rendered_rights_statement", text: "Copyright Not Evaluated"
      expect(page).to have_css ".attribute.visibility", text: "open"
      expect(page).to have_css ".attribute.member_of_collections", text: "Title"
      expect(page).to have_css ".attribute.artists", text: "name1 name2, artist signature"
      expect(page).to have_css ".attribute.ce1", text: "2017"
      expect(page).to have_css ".attribute.ce2", text: "2018"
      expect(page).to have_css ".attribute.citations", text: "short-title part number"
      expect(page).to have_css ".attribute.color", text: "test value"
      expect(page).to have_css ".attribute.denomination", text: "test value"
      expect(page).to have_css ".attribute.edge", text: "test value"
      expect(page).to have_css ".attribute.era", text: "test value"
      expect(page).to have_css ".attribute.master", text: "name1 name2 epithet (1868 - 1963)"
      expect(page).to have_css ".attribute.metal", text: "test value"
      expect(page).to have_css ".attribute.notes", text: "note"
      expect(page).to have_css ".attribute.object_date", text: "test value"
      expect(page).to have_css ".attribute.object_type", text: "test value"
      expect(page).to have_css ".attribute.obverse_attributes", text: "attribute name, attribute description"
      expect(page).to have_css ".attribute.obverse_figure", text: "test value"
      expect(page).to have_css ".attribute.obverse_figure_relationship", text: "test value"
      expect(page).to have_css ".attribute.obverse_figure_description", text: "test value"
      expect(page).to have_css ".attribute.obverse_legend", text: "test value"
      expect(page).to have_css ".attribute.obverse_orientation", text: "test value"
      expect(page).to have_css ".attribute.obverse_part", text: "test value"
      expect(page).to have_css ".attribute.obverse_symbol", text: "test value"
      expect(page).to have_css ".attribute.rendered_place", text: "city, state, region"
      expect(page).to have_css ".attribute.replaces", text: "test value"
      expect(page).to have_css ".attribute.reverse_attributes", text: "attribute name, attribute description"
      expect(page).to have_css ".attribute.reverse_figure", text: "test value"
      expect(page).to have_css ".attribute.reverse_figure_relationship", text: "test value"
      expect(page).to have_css ".attribute.reverse_figure_description", text: "test value"
      expect(page).to have_css ".attribute.reverse_legend", text: "test value"
      expect(page).to have_css ".attribute.reverse_orientation", text: "test value"
      expect(page).to have_css ".attribute.reverse_part", text: "test value"
      expect(page).to have_css ".attribute.reverse_symbol", text: "test value"
      expect(page).to have_css ".attribute.ruler", text: "name1 name2 epithet (1868 - 1963)"
      expect(page).to have_css ".attribute.series", text: "test value"
      expect(page).to have_css ".attribute.shape", text: "test value"
      expect(page).to have_css ".attribute.subjects", text: "Animal, unicorn"
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
