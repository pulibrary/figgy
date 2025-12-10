# frozen_string_literal: true
require "rails_helper"

RSpec.describe "preservation_audits/show.html.erb" do
  it "has a link to the fixity dashboard" do
    audit = FactoryBot.create(:preservation_audit)
    fail1 = FactoryBot.create(:preservation_check_failure, preservation_audit: audit)
    FactoryBot.create(:preservation_check_failure, preservation_audit: audit)
    sign_in FactoryBot.create(:admin)
    assign :preservation_audit, audit
    render

    expect(rendered).to have_text("Failures: 2", normalize_ws: true)
    expect(rendered).to have_css("h2", text: "Failures")
    expect(rendered).to have_link(fail1.resource_id, text: fail1.resource_id)
  end
end
