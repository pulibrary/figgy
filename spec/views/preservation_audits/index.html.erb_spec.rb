# frozen_string_literal: true
require "rails_helper"

RSpec.describe "preservation_audits/index.html.erb" do
  it "has audit info and details links" do
    audit = FactoryBot.create(:preservation_audit)
    FactoryBot.create(:preservation_check_failure, preservation_audit: audit)
    sign_in FactoryBot.create(:admin)
    assign :preservation_audits, [audit]
    render

    expect(rendered).to have_link("Show this preservation audit", href: preservation_audit_path(audit.id))
    expect(rendered).to have_text("Failures: 1", normalize_ws: true)
  end
end
