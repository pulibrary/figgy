# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Numismatic Issue" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  scenario "detaching a monogram from an issue", js: true do
    monogram = FactoryBot.create_for_repository(:numismatic_monogram)
    issue = FactoryBot.create_for_repository(:numismatic_issue, numismatic_monogram_ids: [monogram.id])
    ChangeSetPersister.default.save(change_set: ChangeSet.for(issue))

    visit solr_document_path(id: issue.id)
    expect(page).to have_content "Test Monogram"

    visit edit_numismatics_issue_path(id: issue.id)
    click_link(href: "#collapseMonograms")
    within(find(".monogram-options")) do
      click_button "Detach"
    end
    click_button "Save"

    expect(page).not_to have_content "Test Monogram"
  end

  scenario "ajax-select components are added to the page", js: true do
    person = FactoryBot.create_for_repository(:numismatic_person, name1: "name1", name2: "name2")
    issue = FactoryBot.create_for_repository(:numismatic_issue)
    ChangeSetPersister.default.save(change_set: ChangeSet.for(person))
    ChangeSetPersister.default.save(change_set: ChangeSet.for(issue))

    visit edit_numismatics_issue_path(id: issue.id)

    expect(page).to have_selector(".v-select")
  end
end
