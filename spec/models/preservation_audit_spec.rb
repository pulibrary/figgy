# frozen_string_literal: true
require "rails_helper"

RSpec.describe PreservationAudit, type: :model do
  it "creates a valid preservation audit" do
    expect(described_class.create(status: "in_process", extent: "full", batch_id: "bc7f822afbb40747")).to be_valid
  end

  it "requires a batch id" do
    expect(described_class.create(status: "in_process", extent: "full")).not_to be_valid
  end

  it "requires specific status value" do
    audit = FactoryBot.create(:preservation_audit)
    audit.status = "in_process"
    expect(audit).to be_valid
    audit.status = "success"
    expect(audit).to be_valid
    audit.status = "failure"
    expect(audit).to be_valid
    audit.status = "complete"
    expect(audit).to be_valid
    audit.status = "dead"
    expect(audit).to be_valid
    audit.status = "something_else"
    expect(audit).not_to be_valid
  end

  it "requires specific extent" do
    audit = FactoryBot.create(:preservation_audit)
    audit.extent = "full"
    expect(audit).to be_valid
    audit.extent = "partial"
    expect(audit).to be_valid
    audit.extent = "something_else"
    expect(audit).not_to be_valid
  end

  it "has preservation check failures" do
    audit = FactoryBot.create(
      :preservation_audit,
      status: "in_process",
      extent: "full",
      batch_id: "bc7f822afbb40747"
    )
    failure1 = FactoryBot.create(:preservation_check_failure, resource_id: "abc123", preservation_audit: audit)
    failure2 = FactoryBot.create(:preservation_check_failure, resource_id: "xyz789", preservation_audit: audit)

    expect(audit.preservation_check_failures).to contain_exactly(failure1, failure2)
  end
end
