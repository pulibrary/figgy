# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Numismatics::Issue", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:issue) do
    FactoryBot.build(:numismatic_issue,
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
    it "permits users to save a new object types" do
      visit new_numismatics_issue_path

      expect(page).to have_css("#select2-numismatics_issue_object_type-container")
      expect(page).to have_css("#select2-numismatics_issue_denomination-container")
      expect(page).to have_css("#select2-numismatics_issue_metal-container")
      expect(page).to have_css("#select2-numismatics_issue_shape-container")
      expect(page).to have_css("#select2-numismatics_issue_color-container")
      expect(page).to have_css("#select2-numismatics_issue_edge-container")

      page.find("#select2-numismatics_issue_object_type-container").click
      page.find(".select2-search__field", visible: false).send_keys("coin2", :enter)
      page.find(".save").click

      expect(page).to have_css(".attribute.object_type", text: "coin2")
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

        page.find("#select2-numismatics_issue_object_type-container").click
        page.find(".select2-search__field", visible: false).send_keys("coin3", :enter)
        page.find(".save").click

        expect(page).to have_css(".attribute.object_type", text: "coin3")
      end

      it "persists already saved denominations" do
        visit edit_numismatics_issue_path(id: persisted.id)

        hidden = page.find("body #main form.edit_numismatics_issue input[type='hidden']#denomination", visible: false)
        expect(hidden["value"]).to eq("1/2 Penny")
      end
    end
  end
end
