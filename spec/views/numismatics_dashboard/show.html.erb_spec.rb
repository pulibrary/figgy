# frozen_string_literal: true
require "rails_helper"

RSpec.describe "numismatics_dashboard/show" do
  before do
    sign_in user if user
    render
  end

  context "when the user is an admin" do
    let(:user) { FactoryBot.create(:admin) }
    let(:view_issues_path) do
      search_catalog_path(params: { "f": { "human_readable_type_ssim": ["Issue"] }, "q": "" })
    end

    it "has cards" do
      expect(rendered).to have_css("h3", text: "Numismatics")
      expect(rendered).to have_selector("div.card.classify-accessions", text: "Accessions")
      expect(rendered).to have_css("div.card.work-type", text: "Firms")
      expect(rendered).to have_css("div.card.classify-monograms", text: "Monograms")
      expect(rendered).to have_css("div.card.classify-people", text: "People")
      expect(rendered).to have_css("div.card.classify-places", text: "Places")
      expect(rendered).to have_css("div.card.classify-references", text: "References")
      expect(rendered).to have_link("Manage", href: numismatics_references_path)
      expect(rendered).to have_link "New Issue", href: new_numismatics_issue_path
      expect(rendered).to have_link("View", href: view_issues_path)
    end
  end
end
