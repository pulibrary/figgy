# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Numismatics::Issues" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:numismatic_issue) do
    res = FactoryBot.create_for_repository(:numismatic_issue)
    persister.save(resource: res)
  end
  let(:change_set) do
    Numismatics::IssueChangeSet.new(numismatic_issue)
  end
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    stub_ezid(shoulder: "99999/fk4", blade: "123456")

    change_set_persister.save(change_set: change_set)
    sign_in user
  end

  scenario "form presented when creating a new resource" do
    visit new_numismatics_issue_path

    expect(page).not_to have_css '.select[for="numismatics_issue_rights_statement"]', text: "Rights Statement"
    expect(page).not_to have_field "Rights Note"
    expect(page).not_to have_css '.select[for="numismatics_issue_member_of_collection_ids"]', text: "Collections"
    expect(page).to have_field "Color"
    expect(page).to have_field "Date of object"
    expect(page).to have_field "Earliest date" # For the date range sequence
    expect(page).to have_field "Latest date" # For the date range
    expect(page).to have_field "Description"
    expect(page).to have_field "Denomination"
    expect(page).to have_field "Edge"
    expect(page).to have_field "Era"
    expect(page).to have_selector("label", text: "Master")
    expect(page).to have_field "Metal"
    expect(page).to have_field "Name"
    expect(page).to have_field "Note"
    expect(page).to have_field "Number"
    expect(page).to have_selector("label", text: "Numismatic reference")
    expect(page).to have_field "Part"
    expect(page).to have_selector("label", text: "Person")
    expect(page).to have_selector("label", text: "Minting Location")
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
    expect(page).to have_selector("label", text: "Ruler")
    expect(page).to have_field "Series"
    expect(page).to have_field "Shape"
    expect(page).to have_field "Side"
    expect(page).to have_field "Signature"
    expect(page).not_to have_field "State"
    expect(page).to have_field "Subject"
    expect(page).to have_field "Type"
    expect(page).to have_field "Workshop"
    expect(page).to have_css "a.btn.btn-sm.btn-primary.new-link", text: "New Place"
    expect(page).to have_css "a.btn.btn-sm.btn-primary.new-link", text: "New Person"
    expect(page).to have_css "a.btn.btn-sm.btn-primary.new-link", text: "New Monogram"
    expect(page).to have_css "a.btn.btn-sm.btn-primary.new-link", text: "New Master"
    expect(page).to have_css "a.btn.btn-sm.btn-primary.new-link", text: "New Reference"
    expect(page).to have_css "a.btn.btn-sm.btn-primary.new-link", text: "New Ruler"
    expect(page).to have_css "div.panel.panel-default div.panel-body div.col-sm-6 div.form-group div.col-sm-6 div.form-group input#numismatics_issue_earliest_date"
    expect(page).to have_css "div.panel.panel-default div.panel-body div.col-sm-6 div.form-group div.col-sm-6 div.form-group input#numismatics_issue_latest_date"
    expect(page).to have_css "div.panel.panel-default div.panel-body div.col-sm-6 div.form-group div.col-sm-6 div.form-group input#numismatics_issue_era"
    expect(page).to have_css "div.panel.panel-default div.panel-body div.col-sm-6 div.form-group div.col-sm-6 div.form-group input#numismatics_issue_object_date"
  end

  context "when another issue already exists", js: true do
    scenario "a new issue gets blank default values" do
      preexisting_issue = FactoryBot.build(
        :numismatic_issue,
        shape: "round",
        color: "green",
        metal: "copper",
        edge: "serrated",
        denomination: "dollar",
        object_type: "coin"
      )
      change_set_persister.save(change_set: DynamicChangeSet.new(preexisting_issue))

      visit new_numismatics_issue_path

      # default values
      expect(page.find("#select2-numismatics_issue_shape-container").text).to eq "Nothing selected"
      expect(page.find("#select2-numismatics_issue_color-container").text).to eq "Nothing selected"
      expect(page.find("#select2-numismatics_issue_metal-container").text).to eq "Nothing selected"
      expect(page.find("#select2-numismatics_issue_edge-container").text).to eq "Nothing selected"
      expect(page.find("#select2-numismatics_issue_denomination-container").text).to eq "Nothing selected"
      expect(page.find("#select2-numismatics_issue_object_type-container").text).to eq "Nothing selected"
      expect(page).to have_select("Shape", selected: "")
      expect(page).to have_select("Color", selected: "")
      expect(page).to have_select("Metal", selected: "")
      expect(page).to have_select("Edge", selected: "")
      expect(page).to have_select("Denomination", selected: "")
      expect(page).to have_select("Object type", selected: "")
    end
  end

  scenario "users can save a new issue" do
    visit new_numismatics_issue_path

    page.fill_in "numismatics_issue_era", with: "test era"

    page.click_on "Save"

    expect(page).to have_css ".attribute.era", text: "test era"
  end

  scenario "users can save a new issue and create another" do
    visit new_numismatics_issue_path

    page.fill_in "numismatics_issue_era", with: "test era"

    page.click_on "Save and Duplicate Metadata"

    expect(page).to have_content "Issue 2 Saved, Creating Another..."
    expect(page).to have_field "numismatics_issue_era", with: "test era"
  end

  context "viewing a resource" do
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:numismatic_reference) { FactoryBot.create_for_repository(:numismatic_reference) }
    let(:person) { FactoryBot.create_for_repository(:numismatic_person) }
    let(:numismatic_artist) { Numismatics::Artist.new(person_id: person.id, signature: "artist signature") }
    let(:numismatic_attribute) { Numismatics::Attribute.new(description: "attribute description", name: "attribute name") }
    let(:numismatic_note) { Numismatics::Note.new(note: "note", type: "note type") }
    let(:numismatic_citation) { Numismatics::Citation.new(part: "part", number: "number", numismatic_reference_id: numismatic_reference.id) }
    let(:numismatic_place) { FactoryBot.create_for_repository(:numismatic_place) }
    let(:numismatic_person) { FactoryBot.create_for_repository(:numismatic_person) }
    let(:numismatic_subject) { Numismatics::Subject.new(type: "Animal", subject: "unicorn") }
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
        earliest_date: "2017",
        latest_date: "2018",
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

    scenario "all fields are displayed" do
      visit solr_document_path numismatic_issue
      expect(page).to have_css ".attribute.rendered_rights_statement", text: "Copyright Not Evaluated"
      expect(page).to have_css ".attribute.visibility", text: "open"
      expect(page).to have_css ".attribute.member_of_collections", text: "Title"
      expect(page).to have_css ".attribute.artists", text: "name1 name2, artist signature"
      expect(page).to have_css ".attribute.earliest_date", text: "2017"
      expect(page).to have_css ".attribute.latest_date", text: "2018"
      expect(page).to have_css ".attribute.citations", text: "short-title part number"
      expect(page).to have_css ".attribute.color", text: "test value"
      expect(page).to have_css ".attribute.denomination", text: "test value"
      expect(page).to have_css ".attribute.edge", text: "test value"
      expect(page).to have_css ".attribute.era", text: "test value"
      expect(page).to have_css ".attribute.master", text: "name1 name2 epithet (1868 to 1963)"
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
      expect(page).to have_css ".attribute.rulers", text: "name1 name2 epithet (1868 to 1963)"
      expect(page).to have_css ".attribute.series", text: "test value"
      expect(page).to have_css ".attribute.shape", text: "test value"
      expect(page).to have_css ".attribute.subjects", text: "Animal, unicorn"
      expect(page).to have_css ".attribute.workshop", text: "test value"
    end
  end

  context "with child Numismatics::Coin resources" do
    let(:member) do
      persister.save(resource: FactoryBot.create_for_repository(:coin))
    end
    let(:parent) do
      persister.save(resource: FactoryBot.create_for_repository(:numismatic_issue, member_ids: [member.id]))
    end
    before do
      parent
    end

    scenario "saved Numismatics::Coins are displayed as members" do
      visit solr_document_path(parent)

      expect(page).to have_selector "h3", text: "Coins"
      expect(page).to have_selector "td", text: "Coin: #{member.coin_number}"
    end
  end

  context "with referenced Numismatics::Monogram resources" do
    let(:monogram1) do
      persister.save(resource: FactoryBot.create_for_repository(:numismatic_monogram))
    end
    let(:file_set) do
      persister.save(resource: FactoryBot.create_for_repository(:file_set))
    end
    let(:monogram2) do
      persister.save(resource: FactoryBot.create_for_repository(:numismatic_monogram, member_ids: [file_set.id]))
    end
    let(:parent) do
      persister.save(resource: FactoryBot.create_for_repository(:numismatic_issue, numismatic_monogram_ids: [monogram2.id]))
    end
    before do
      monogram1
      parent
    end

    context "when editing an existing issue" do
      let(:numismatic_issue) do
        res = FactoryBot.create_for_repository(:numismatic_issue, era: "test era")
        persister.save(resource: res)
      end

      before do
        visit edit_numismatics_issue_path(id: numismatic_issue.id)
      end

      scenario "users can update any given issue" do
        page.fill_in "numismatics_issue_era", with: "test era 2"

        page.click_on "Save"

        expect(page).to have_css ".attribute.era", text: "test era 2"
      end

      scenario "users can create a new issue with duplicated metadata" do
        page.fill_in "numismatics_issue_era", with: "test era 2"

        page.click_on "Save and Duplicate Metadata"

        expect(page).to have_content "Issue 1 Saved, Creating Another..."
        expect(page).to have_field "numismatics_issue_era", with: "test era 2"
      end
    end

    scenario "when users are editing the Numismatics::Issue resource", js: true do
      visit edit_numismatics_issue_path(parent)

      doc = Nokogiri::HTML(page.body)
      expect(doc.xpath("//issue-monograms")).not_to be_empty

      issue_monogram_elements = doc.xpath("//issue-monograms")
      expect(issue_monogram_elements).not_to be_empty

      issue_monogram_element = issue_monogram_elements.first
      attributes = JSON.parse(issue_monogram_element[":members"])
      expect(attributes).to be_a Array
      expect(attributes.length).to eq(2)

      first_attribute = attributes.first
      expect(first_attribute.keys).to include("id", "url", "thumbnail", "title", "attached")
      expect(first_attribute["id"]).to eq(monogram2.id.to_s)
      expect(first_attribute["title"]).to eq("Test Monogram")
      expect(first_attribute["attached"]).to be true
      expect(first_attribute["thumbnail"]).to include(file_set.id.to_s)

      last_attribute = attributes.last
      expect(last_attribute.keys).to include("id", "url", "thumbnail", "title", "attached")
      expect(last_attribute["id"]).to eq(monogram1.id.to_s)
      expect(last_attribute["title"]).to eq("Test Monogram")
      expect(last_attribute["attached"]).to be false
      expect(page).to have_css "a.btn.btn-sm.btn-primary.new-link", text: "New Place"
      expect(page).to have_css "a.btn.btn-sm.btn-primary.new-link", text: "New Person"
      expect(page).to have_css "a.btn.btn-sm.btn-primary.new-link", text: "New Monogram"
    end
  end

  describe "form editing", js: true do
    let(:adapter) { Valkyrie::MetadataAdapter.find(:index_solr) }
    let(:numismatic_issue) do
      FactoryBot.create_for_repository(:numismatic_issue,
                                       color: "green",
                                       denomination: "1/2 Penny",
                                       edge: "serrated",
                                       metal: "copper",
                                       object_type: "coin",
                                       obverse_figure: "obv figure",
                                       obverse_orientation: "obv orientation",
                                       obverse_part: "obv part",
                                       reverse_figure: "rev figure",
                                       reverse_orientation: "rev orientation",
                                       reverse_part: "rev part",
                                       shape: "round")
    end

    it "displays select boxes for some properties" do
      visit new_numismatics_issue_path
      expect(page).to have_css("#numismatics_issue_color.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_denomination.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_edge.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_metal.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_object_type.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_obverse_figure.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_obverse_orientation.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_obverse_part.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_reverse_figure.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_reverse_orientation.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_reverse_part.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_shape.select2", visible: false)
    end

    it "displays a collapsed Monograms panel" do
      visit new_numismatics_issue_path
      page.find(".panel-heading a.collapsed.monograms").click
      expect(page).not_to have_css(".panel-heading a.collapsed.monograms")
    end

    context "when Issues have been saved" do
      let(:persisted) do
        change_set = Numismatics::IssueChangeSet.new(numismatic_issue)
        change_set_persister.save(change_set: change_set)
      end

      it "permits users to select from existing object types" do
        visit edit_numismatics_issue_path(id: persisted.id)

        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#color", visible: false)
        expect(hidden["value"]).to eq("green")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#denomination", visible: false)
        expect(hidden["value"]).to eq("1/2 Penny")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#edge", visible: false)
        expect(hidden["value"]).to eq("serrated")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#metal", visible: false)
        expect(hidden["value"]).to eq("copper")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#object_type", visible: false)
        expect(hidden["value"]).to eq("coin")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#obverse_figure", visible: false)
        expect(hidden["value"]).to eq("obv figure")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#obverse_orientation", visible: false)
        expect(hidden["value"]).to eq("obv orientation")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#obverse_part", visible: false)
        expect(hidden["value"]).to eq("obv part")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#reverse_figure", visible: false)
        expect(hidden["value"]).to eq("rev figure")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#reverse_orientation", visible: false)
        expect(hidden["value"]).to eq("rev orientation")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#reverse_part", visible: false)
        expect(hidden["value"]).to eq("rev part")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#shape", visible: false)
        expect(hidden["value"]).to eq("round")

        expect(page).to have_selector("option", text: "coin")
        expect(page).to have_selector("option", text: "1/2 Penny")
        expect(page).to have_selector("option", text: "copper")
        expect(page).to have_selector("option", text: "round")
        expect(page).to have_selector("option", text: "green")
        expect(page).to have_selector("option", text: "serrated")
        expect(page).to have_selector("option", text: "obv figure")
        expect(page).to have_selector("option", text: "obv orientation")
        expect(page).to have_selector("option", text: "obv part")
        expect(page).to have_selector("option", text: "rev figure")
        expect(page).to have_selector("option", text: "rev orientation")
        expect(page).to have_selector("option", text: "rev part")
      end

      it "persists already-saved denominations" do
        visit edit_numismatics_issue_path(id: persisted.id)

        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#denomination", visible: false)
        expect(hidden["value"]).to eq("1/2 Penny")
      end

      it "initializes the correct selected value in autocomplete fields" do
        visit edit_numismatics_issue_path(id: persisted.id)

        expect(page).to have_select("Color", selected: ["green"])
        expect(page).to have_select("Metal", selected: ["copper"])
        expect(page).to have_select("Edge", selected: ["serrated"])
        expect(page).to have_select("Denomination", selected: ["1/2 Penny"])
        expect(page).to have_select("Object type", selected: ["coin"])
        expect(page).to have_select("Shape", selected: ["round"])
      end
    end
  end
end
