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
      search_catalog_path(params: {f: {human_readable_type_ssim: ["Issue"]}, q: ""})
    end

    it "has panels" do
      expect(rendered).to have_css("h3", text: "Numismatics")
      expect(rendered).to have_css("ul.classify-work.classify-accessions > li > h4")
      expect(rendered).to have_css("ul.classify-work.classify-firms > li > h4")
      expect(rendered).to have_css("ul.classify-work.classify-monograms > li > h4")
      expect(rendered).to have_css("ul.classify-work.classify-people > li > h4")
      expect(rendered).to have_css("ul.classify-work.classify-places > li > h4")
      expect(rendered).to have_css("ul.classify-work.classify-references > li > h4")
      expect(rendered).to have_link("Manage", href: numismatics_references_path)
      expect(rendered).to have_link "New Issue", href: new_numismatics_issue_path
      expect(rendered).to have_link("View", href: view_issues_path)
    end
  end
end
