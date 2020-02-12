# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Numismatics::Issue", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:issue) do
    FactoryBot.create_for_repository(:numismatic_issue,
                                     object_type: "coin",
                                     denomination: "1/2 Penny",
                                     metal: "copper",
                                     shape: "round",
                                     color: "green",
                                     edge: "test value")
  end
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter) }

  before do
    sign_in user
  end

  describe "form editing" do
    it "displays select boxes for some properties" do
      visit new_numismatics_issue_path
      expect(page).to have_css("#numismatics_issue_object_type.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_denomination.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_metal.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_shape.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_color.select2", visible: false)
      expect(page).to have_css("#numismatics_issue_edge.select2", visible: false)
    end

    context "when Issues have been saved" do
      let(:persisted) do
        change_set = Numismatics::IssueChangeSet.new(issue)
        change_set_persister.save(change_set: change_set)
      end

      it "permits users to select from existing object types" do
        visit edit_numismatics_issue_path(id: persisted.id)

        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#object_type", visible: false)
        expect(hidden["value"]).to eq("coin")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#denomination", visible: false)
        expect(hidden["value"]).to eq("1/2 Penny")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#metal", visible: false)
        expect(hidden["value"]).to eq("copper")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#shape", visible: false)
        expect(hidden["value"]).to eq("round")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#color", visible: false)
        expect(hidden["value"]).to eq("green")
        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#edge", visible: false)
        expect(hidden["value"]).to eq("test value")

        expect(page).to have_selector("option", text: "coin")
        expect(page).to have_selector("option", text: "1/2 Penny")
        expect(page).to have_selector("option", text: "copper")
        expect(page).to have_selector("option", text: "round")
        expect(page).to have_selector("option", text: "green")
        expect(page).to have_selector("option", text: "test value")
      end

      it "persists already saved denominations" do
        visit edit_numismatics_issue_path(id: persisted.id)

        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#denomination", visible: false)
        expect(hidden["value"]).to eq("1/2 Penny")
      end
    end
  end
end
