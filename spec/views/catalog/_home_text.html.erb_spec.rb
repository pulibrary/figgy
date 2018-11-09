# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_home_text.html.erb" do
  before do
    sign_in user if user
    render
  end

  context "when the user is an admin" do
    let(:user) { FactoryBot.create(:admin) }

    it "has a link to the fixity dashboard" do
      expect(rendered).to have_link "Fixity Dashboard"
    end

    it "has a links to bulk ingest resources" do
      expect(rendered).to have_link "Bulk Ingest"
    end

    it "has panels" do
      expect(rendered).to have_css("div.panel-heading", text: "Numismatics")
      expect(rendered).to have_css("h4.title", text: "Media Reserve")
      expect(rendered).to have_css("div.panel-heading", text: "Media Reserves")
      expect(rendered).to have_link "Add New", href: new_media_reserve_scanned_resources_path
    end
  end

  context "when the user is patron" do
    let(:user) { FactoryBot.create(:campus_patron) }

    it "does not have a link to the fixity dashboard" do
      expect(rendered).not_to have_link "Fixity Dashboard"
    end
  end
end
