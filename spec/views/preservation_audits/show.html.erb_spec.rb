require "rails_helper"

RSpec.describe "preservation_audits/show.html.erb" do
  it "has audit info and links to failed resources" do
    audit = FactoryBot.create(:preservation_audit)
    fail1 = FactoryBot.create(:preservation_check_failure, preservation_audit: audit)
    FactoryBot.create(:preservation_check_failure, preservation_audit: audit)
    sign_in FactoryBot.create(:admin)
    assign :preservation_audit, audit
    render

    expect(rendered).to have_text("Failures: 2", normalize_ws: true)
    expect(rendered).to have_text("Created at")
    expect(rendered).to have_css("h2", text: "Failures")
    expect(rendered).to have_link(fail1.resource_id, text: fail1.resource_id)
  end

  it "has a link to an audit it reran" do
    audit = FactoryBot.create(:preservation_audit)
    rerun = FactoryBot.create(:preservation_audit, extent: "partial", ids_from: audit)
    FactoryBot.create(:preservation_check_failure, preservation_audit: audit)
    sign_in FactoryBot.create(:admin)
    assign :preservation_audit, rerun
    render

    expect(rendered).to have_text("This audit only ran on ids from", normalize_ws: true)
    expect(rendered).to have_link("audit #{audit.id}", href: preservation_audit_path(audit.id))
  end
end
