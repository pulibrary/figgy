require "rails_helper"

RSpec.describe PreservationAudit, type: :model do
  it "creates a valid preservation audit" do
    expect(described_class.create(status: "in_process", extent: "full", batch_id: "bc7f822afbb40747")).to be_valid
  end

  it "requires a batch id" do
    expect(described_class.create(status: "in_process", extent: "full")).not_to be_valid
  end

  it "requires specific status value" do
    pa = FactoryBot.create(:preservation_audit)
    pa.status = "in_process"
    expect(pa).to be_valid
    pa.status = "success"
    expect(pa).to be_valid
    pa.status = "failure"
    expect(pa).to be_valid
    pa.status = "something_else"
    expect(pa).not_to be_valid
  end

  it "requires specific extent" do
    pa = FactoryBot.create(:preservation_audit)
    pa.extent = "full"
    expect(pa).to be_valid
    pa.extent = "partial"
    expect(pa).to be_valid
    pa.extent = "something_else"
    expect(pa).not_to be_valid
  end
end
