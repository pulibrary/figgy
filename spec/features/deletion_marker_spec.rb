# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Deletion Marker" do
  let(:user) { FactoryBot.create(:admin) }
  let(:deletion_marker) { FactoryBot.create_for_repository(:deletion_marker) }

  before do
    sign_in user
    ChangeSetPersister.default.save(change_set: ChangeSet.for(deletion_marker))
  end

  after do
    ChangeSetPersister.default.delete(change_set: ChangeSet.for(deletion_marker))
  end

  context "when running in production" do
    scenario "users does not see Delete button on show page" do
      env = ActiveSupport::EnvironmentInquirer.new("production")
      allow(Rails).to receive(:env).and_return(env)
      visit solr_document_path deletion_marker
      expect(page).not_to have_link "Delete This Deletion Marker"
    end
  end

  context "when not running in production" do
    scenario "users does Delete button on show page" do
      visit solr_document_path deletion_marker
      expect(page).to have_link "Delete This Deletion Marker"
    end
  end
end
